#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

NuigRnag::Application.load_tasks

require 'rake/testtask'
require 'bundler'
require 'jettywrapper'
require 'ci/reporter/rake/rspec'

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'nuig-rnag'
  rdoc.options << '--line-numbers'
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include('*.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('app/*.rb')
end

namespace :jetty do

  desc "return development jetty to its pristine state, as pulled from git"
  task :reset => ['jetty:stop'] do
    system("cd jetty && git reset --hard HEAD && git clean -dfx && cd ..")
    sleep 2
  end

end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rspec => ['ci:setup:rspec']) do |rspec|
  rspec.pattern = FileList['spec/*_spec.rb']
end

desc "Run Continuous Integration"
task :ci => ['jetty:reset', 'jetty:config', 'ci_clean'] do
  ENV['environment'] = "test"
  Rake::Task['db:migrate'].invoke
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait]= 120
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['cucumber'].invoke
#    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error

  Rake::Task["rdoc"].invoke
end

desc "Run Continuous Integration-spec"
task :ci_spec => ['jetty:reset', 'jetty:config', 'ci_clean'] do
  ENV['environment'] = "test"
  Rake::Task['db:migrate'].invoke
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait]= 120
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error

  Rake::Task["rdoc"].invoke
end

desc "Clean CI environment"
task :ci_clean do
  rm_rf 'features/reports'
end

namespace :rvm do

  desc 'Trust rvmrc file'
  task :trust_rvmrc do
    system(". ~/.rvm/scripts/rvm && rvm rvmrc trust .rvmrc && rvm rvmrc load")
  end

end

task :restart_workers => :environment do
  pids = Array.new
  Resque.workers.each do |worker|
    pids << worker.to_s.split(/:/).second
  end
  if pids.size > 0
    system("kill -QUIT #{pids.join(' ')}")
  end
end

namespace :solr do
  namespace :dri do
    desc 'reindex'
    task :reindex do
      GenericFile.find(:all).each do |obj|
        obj.update_index
      end

      Batch.find(:all).each do |obj|
        obj.update_index
      end
    end
  end
end
