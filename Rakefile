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
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('app/*.rb')
end
