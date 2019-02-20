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

  task restart: :environment do
    Rake::Task['jetty:stop'].invoke
    Rake::Task['jetty:start'].invoke
  end

  task config: :environment do
    Rake::Task['jetty:start'].invoke unless solr.started?

    begin
      update_core('development')
      update_core('test')
    rescue Exception => e
      puts e
    end
  end

  # https://github.com/samvera-deprecated/jettywrapper/wiki/Using-jettywrapper#setting-up-jetty-for-your-project
  desc 'copies config files from solr/conf to the active solr dir'
  task config_update: :environment do
    solr_config_files.each do |cf|
      cp(
        "#{cf}",
        "#{solr.instance_dir}/server/solr/#{Rails.env}/conf/",
        verbose: true
      )
    end
  end

  desc 'shows differences between solr/conf and the active solr dir. use update_config to copy solr/conf xml files to the active solr dir'
  task config_diff: :environment do
    solr_config_files.each do |cf|
      rf = "#{solr.instance_dir}/server/solr/#{Rails.env}/conf/#{File.basename(cf)}"
      system("diff #{cf} #{rf}")
    end
  end

  # @param [String] env_name
  # for env, create new core with latest config if core doesn't exist
  # if core does exist, copy config
  def update_core(env_name)
    original_env = Rails.env
    Rails.env = env_name
    client = SolrWrapper::Client.new(solr.url)
    if client.exists?(env_name)
      Rake::Task['jetty:config_update'].invoke
    else
      solr.create(persist: true, name: env_name, dir: solr_config)
    end
  ensure
    Rails.env = original_env
  end

  def solr_config_files
    FileList[File.join(solr_config, '*.xml')]
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
