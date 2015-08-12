require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
    # check passanger stack
    h.check :active_record, :async => false

    #check connection to fedora
    h.check :fedora_headers do |status|
      conn = Faraday.new(ActiveFedora.config.credentials[:url])
      conn.basic_auth(ActiveFedora.config.credentials[:user], ActiveFedora.config.credentials[:password])
      if conn.head().status.eql?(200) 
        status.ok("Fedora active")
      else
        status.fail("Fedora down")
      end
    end

    #h.check :rubydora, :client => ActiveFedora::Base.connection_for_pid(0)
    #h.check :rsolr, :client => Dor::SearchService.solr
    #h.check :directory, :path => Rails.root + "tmp", :permission => [:read, :write]
    #h.check :ping, :host => "smtp.tchpc.tcd.ie", :port => "smtp"
    #h.check :url, :get => "http://repository.dri.ie/"
end
