require 'solr_wrapper'

namespace :jetty do

  task(:config).clear

  desc 'Starts configured solr instances for local development and testing'
  task start: :environment do
    solr.extract_and_configure
    solr.start
  end

  task stop: :environment do
    solr.stop
  end

  task config: :environment do
    Rake::Task['jetty:start'].invoke unless solr.started? 

    client = SolrWrapper::Client.new(solr.url)

    begin
      solr.create(persist: true, name: 'development', dir: solr_config) unless client.exists?('development')
      solr.create(persist: true, name: 'test', dir: solr_config) unless client.exists?('test')
    rescue Exception => e
      puts e
    end
  end

  def solr_config
    File.join(Rails.root, 'solr', 'config')
  end

  def solr
    @solr ||= SolrWrapper.instance
  end

end
