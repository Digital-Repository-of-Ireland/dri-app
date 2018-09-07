require 'rubygems'
require 'capybara/poltergeist'

def zeus_running?
  File.exists? '.zeus.sock'
end

if !zeus_running? && ENV["RUN_COVERAGE"]
    require 'simplecov'
    require 'simplecov-rcov'
    SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
    SimpleCov.start do 
        add_filter "/spec/"
        add_filter "/config/"
    end
end

#Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, :phantomjs => Phantomjs.path)
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include Rails.application.routes.url_helpers
  config.include DeviseRequestSpecHelper, type: :request
  config.include PreservationHelper
end

Rails.application.eager_load!

