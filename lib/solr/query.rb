module Solr
  class Query
    include Enumerable

    def initialize(query, chunk=100, args = {})
      @query = query
      @chunk = chunk
      @args = args
      @cursor_mark = "*"
      @has_more = true
      @sort = "id asc"
    end

    def count
      args = @args.merge(rows: 0)
      params = { q: @query }.merge(args)
      connection.search(params)['numFound'].to_i
    end

    def query
      sort = @args[:sort].present? ? "#{@args[:sort]}, #{@sort}" : @sort
      query_args = if @args[:rows].present?
                     @args.merge({sort: sort})
                   else
                     @args.merge({raw: true, rows: @chunk, sort: sort, cursorMark: @cursor_mark})
                   end

      params = { q: @query }.merge(query_args)
      response = connection.search(params)

      if response['nextCursorMark'].present?
        nextCursorMark = response['nextCursorMark']
        @has_more = false if @cursor_mark == nextCursorMark

        @cursor_mark = nextCursorMark
      else
        @has_more = false
      end

      response.documents
    end

    def connection
      @connection ||= Solr::Query.repository
    end

    def has_more?
      @has_more
    end

    def pop
      self.query
    end

    def each(&block)
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

      def repository
        blacklight_config.repository_class.new(blacklight_config)
      end

      def construct_query_for_ids(id_array)
        ids = id_array.reject(&:blank?)
        return "id:NEVER_USE_THIS_ID" if ids.empty?
        "{!terms f=id}#{ids.join(',')}"
      end
    end
  end
end
