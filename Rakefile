#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

NuigRnag::Application.load_tasks

require 'rake/testtask'
require 'bundler'
require 'jettywrapper'

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

desc "Run Continuous Integration"
task :ci => ['jetty:reset', 'jetty:config'] do
  ENV['environment'] = "test"
  Rake::Task['db:migrate'].invoke
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait]= 120
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['cucumber'].invoke
  end
  raise "test failures: #{error}" if error

  #Rake::Task["doc"].invoke
end

namespace :rvm do

  desc 'Trust rvmrc file'
  task :trust_rvmrc do
    system(". ~/.rvm/scripts/rvm && rvm rvmrc trust .rvmrc && rvm rvmrc load")
  end

end
