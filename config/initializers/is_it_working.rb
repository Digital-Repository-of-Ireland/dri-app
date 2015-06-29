require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
    h.check :active_record, :async => false
    #h.check :rubydora, :client => ActiveFedora::Base.connection_for_pid(0)
    #h.check :rsolr, :client => Dor::SearchService.solr
    #h.check :directory, :path => Rails.root + "tmp", :permission => [:read, :write]
    h.check :ping, :host => "smtp.tchpc.tcd.ie", :port => "smtp"
    h.check :url, :get => "http://repository.dri.ie/"
end
