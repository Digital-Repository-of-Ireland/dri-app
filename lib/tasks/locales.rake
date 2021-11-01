# frozen_string_literal: true
Bundler.require :translations

namespace :locales do
  task :mergefile do
    masterfile = ENV['file']
    if masterfile.blank?
      puts "You must specify a file to merge or run localefiles:mergeall"
      exit
    end
    masterfile = Pathname.new(masterfile).realpath unless Pathname.new(masterfile).absolute?
    puts "Merging #{masterfile}"
    `i18s #{masterfile}`
  end

  task :mergeall do
    files = Dir[Rails.root.to_s + '/**/**/*en.yml']
    files.each do |file|
      ENV['file'] = file
      Rake::Task["locales:mergefile"].execute
    end
  end
end
