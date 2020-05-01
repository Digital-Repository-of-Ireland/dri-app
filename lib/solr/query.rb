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

    def query
      sort = @args[:sort].present? ? "#{@args[:sort]}, #{@sort}" : @sort
      query_args = @args.merge({:raw => true, :rows => @chunk, :sort => sort, :cursorMark => @cursor_mark})

      result = ActiveFedora::SolrService.get(@query, query_args)
      result_docs = result['response']['docs']

      nextCursorMark = result['nextCursorMark']
      if @cursor_mark == nextCursorMark
        @has_more = false
      end

      @cursor_mark = nextCursorMark

      result_docs
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

        objects.each do |object|
          object_doc = SolrDocument.new(object)
          yield(object_doc)
        end
      end
    end

  end
end
