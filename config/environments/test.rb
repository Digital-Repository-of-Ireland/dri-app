DriApp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.mirador_url = 'https://repository.dri.ie/mirador'

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is 'scratch space' for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_files = true
  config.static_cache_control = 'public, max-age=3600'

  # use localhost so js redirects work
  Rails.application.routes.default_url_options[:host] = 'localhost'

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.exceptions_app = self.routes

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Add a default host for devise mailer
  config.action_mailer.default_url_options = { :host => 'localhost' }

  config.eager_load = false

  Deprecation.default_deprecation_behavior = :silence
end
