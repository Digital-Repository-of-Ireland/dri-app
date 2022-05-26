module DRI
  class SolrBadRequest < ::RSolr::Error::Http
    def details
      if response
        error = parse_solr_error_response(response[:body])
        msg = error.split('msg=')
        msg.length > 1 ? msg[1] : error
      end
    end
  end
end
