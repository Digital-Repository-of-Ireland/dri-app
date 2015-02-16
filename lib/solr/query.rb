module Solr
  class Query

    def initialize(query, chunk=100, args = {})
      @query = query
      @chunk = chunk
      @args = args
      @cursor_mark = "*"
      @has_more = true
    end

    def query
      query_args = @args.merge({:raw => true, :rows => @chunk, :sort => 'id asc', :cursorMark => @cursor_mark})

      result = ActiveFedora::SolrService.query(@query, query_args)

      if result['response']['docs'].size < @chunk
        @has_more = false
      end

      result_docs = result['response']['docs']

      @cursor_mark = result['nextCursorMark']

      result_docs
    end

    def has_more?
      @has_more
    end

    def pop
      self.query
    end

  end
end
