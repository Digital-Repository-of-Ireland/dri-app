require 'fcrepo_wrapper'
require 'fcrepo_wrapper/rake_task'
require 'solr_wrapper'

namespace :jetty do

  task(:config).clear

  desc 'Starts configured solr and fedora instances for local development and testing'
  task start: :environment do
    solr.extract_and_configure
    solr.start

    fedora.start
  end

  task stop: :environment do
    solr.stop
    port = fedora.port
    pid = %x(lsof -ti :#{port}).to_i
    Process.kill("TERM", pid) unless pid == 0
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

  def fedora
    @fedora ||= FcrepoWrapper.default_instance
  end
end

namespace :localstack do
  desc 'Start LocalStack'
  task start: :environment do
    s3_dir = 'tmp/s3/'
    FileUtils.mkdir_p(s3_dir) unless Dir.exists?(s3_dir)
    system("SERVICES=s3:8081 DATA_DIR=#{s3_dir} localstack start")
  end
end
