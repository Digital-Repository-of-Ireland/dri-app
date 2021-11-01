# frozen_string_literal: true
require 'solr_wrapper'

namespace :server do
  task(:config).clear

  desc 'Starts configured solr instances for local development and testing'
  task start: :environment do
    solr.extract_and_configure
    solr.start
  end

  task stop: :environment do
    solr.stop
  end

  task restart: :environment do
    Rake::Task['dev:stop'].invoke
    Rake::Task['dev:start'].invoke
  end

  task config: :environment do
    Rake::Task['dev:start'].invoke unless solr.started?

    begin
      update_core('development')
      update_core('test')
    rescue StandardError => e
      puts e
    end
  end

  # https://github.com/samvera-deprecated/jettywrapper/wiki/Using-jettywrapper#setting-up-jetty-for-your-project
  desc 'copies config files from solr/conf to the active solr dir'
  task config_update: :environment do
    config_update(Rails.env)
  end

  desc 'shows differences between solr/conf and the active solr dir. use update_config to copy solr/conf xml files to the active solr dir'
  task config_diff: :environment do
    config_diff(Rails.env)
  end

  # @param [String] env_name
  # for env, create new core with latest config if core doesn't exist
  # if core does exist, copy config
  def update_core(env_name = 'development')
    client = SolrWrapper::Client.new(solr.url)
    if client.exists?(env_name)
      config_update(env_name)
    else
      solr.create(persist: true, name: env_name, dir: solr_config)
    end
  end

  # @param [String] env_name
  def config_diff(env_name = 'development')
    solr_config_files.each do |cf|
      rf = "#{solr.instance_dir}/server/solr/#{env_name}/conf/#{File.basename(cf)}"
      system("diff #{cf} #{rf}")
    end
  end

  # @param [String] env_name
  def config_update(env_name = 'development')
    solr_config_files.each do |cf|
      cp(
        cf,
        "#{solr.instance_dir}/server/solr/#{env_name}/conf/",
        verbose: true
      )
    end
  end

  def solr_config_files
    FileList[File.join(solr_config, '*.xml')]
  end

  def solr_config
    Rails.root.join('solr', 'config')
  end

  def solr
    @solr ||= SolrWrapper.instance
  end
end

namespace :localstack do
  desc 'Start LocalStack'
  task start: :environment do
    s3_dir = 'tmp/s3/'
    FileUtils.mkdir_p(s3_dir) unless Dir.exist?(s3_dir)
    system("SERVICES=s3:8081 DATA_DIR=#{s3_dir} localstack start")
  end
end
