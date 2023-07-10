require 'rubygems'
require 'capybara/rspec'
require 'selenium-webdriver'

if ENV['RUN_COVERAGE']
  require 'simplecov'

  SimpleCov.command_name('RSpec')
  SimpleCov.use_merging(true)
  SimpleCov.merge_timeout(54400)

  SimpleCov.start 'rails' do
    add_filter "/spec/"
    add_filter "/config/"
    add_filter "/features/"
  end
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
		args: %w[headless no-sandbox]
            )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.javascript_driver = :chrome

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.file_fixture_path = "#{::Rails.root}/spec/fixtures"
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include Rails.application.routes.url_helpers
  config.include DeviseRequestSpecHelper, type: :request
  config.include PreservationHelper
end
