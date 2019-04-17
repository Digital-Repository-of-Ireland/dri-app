DriApp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # default host mirador runs on locally after `npm start`
  # config.mirador_url = 'http://localhost:8000'
  config.mirador_url = 'https://repository.dri.ie/mirador'

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  # config.cache_classes = false

  # turn off caching for method results e.g. iiif_manifst call in iiif_controller.rb
  config.cache_store = [:null_store]

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  Rails.application.routes.default_url_options[:host] = 'localhost:3000'

  config.exceptions_app = self.routes

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  #config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Add a default host for devise mailer
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  config.action_mailer.delivery_method = :sendmail

  config.eager_load = false

  # google analytics
  GA.tracker = 'UA-94005055-1'

  cert_path = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
  ENV['SSL_CERT_FILE'] = cert_path

  Deprecation.default_deprecation_behavior = :silence
end
