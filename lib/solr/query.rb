# frozen_string_literal: true
module Solr
  class Query
    include Enumerable

    def initialize(query, chunk = 1000, args = {})
      @query = query
      @chunk = chunk
      @args = args
      @cursor_mark = "*"
      @has_more = true
      @sort = "id asc"
    end

    def count
      args = @args.merge(rows: 0, qt: 'standard', uf: '* _query_')
      params = { q: @query }.merge(args)
      response = solr_index.connection.get('select', params: params)['response']
      response['numFound'].to_i
    end

    def get
      args = @args.merge(q: @query, qt: 'standard', uf: '* _query_')
      response = solr_index.connection.get('select', params: args)
      CatalogController.blacklight_config.response_model.new(
        response,
        args,
        document_model: CatalogController.blacklight_config.document_model,
        blacklight_config: CatalogController.blacklight_config
      )
    end

    def query
      sort = @args[:sort].present? ? "#{@args[:sort]}, #{@sort}" : @sort
      query_args = if @args[:rows].present?
                        @args.merge({ sort: sort, uf: '* _query_' })
                      else
                        @args.merge({ uf: '* _query_', raw: true, rows: @chunk, sort: sort, cursorMark: @cursor_mark })
                      end
      params = { q: @query }.merge(query_args)
      response = solr_index.search(params)

      if response['response']['numFound'].to_i < query_args[:rows].to_i
        @has_more = false
      elsif response['nextCursorMark'].present?
        next_cursor_mark = response['nextCursorMark']
        @has_more = false if @cursor_mark == next_cursor_mark

        @cursor_mark = next_cursor_mark
      else
        @has_more = false
      end
      response.documents
    end

    def solr_index
      @solr_index ||= Solr::Query.repository
    end

    def has_more?
      @has_more
    end

    def pop
      query
    end

    def each
      while has_more?
        objects = pop

        objects.each do |object_doc|
          yield(object_doc)
        end
      end
    end

    class << self
      def find(id)
        response = repository.find(id)
        response.documents.first unless response.documents.empty?
      rescue Blacklight::Exceptions::RecordNotFound
        nil
      end

      def find_by_alternate_id(id)
        args = { q: "alternate_id:\"#{id}\"", fl: "*", rows: 1 }
        response = repository.connection.get("select", params: args)

        bl_response = CatalogController.blacklight_config.response_model.new(
                        response,
                        args,
                        document_model: CatalogController.blacklight_config.document_model,
                        blacklight_config: CatalogController.blacklight_config
                      )
        return bl_response.documents.first unless bl_response.documents.empty?
      end

      def repository
        CatalogController.blacklight_config.repository_class.new(CatalogController.blacklight_config)
      end

      def construct_query_for_ids(id_array, id_field = 'id')
        ids = id_array.reject(&:blank?)
        return "#{id_field}:NEVER_USE_THIS_ID" if ids.empty?
        "{!terms f=#{id_field}}#{ids.join(',')}"
      end
    end
  end
end
