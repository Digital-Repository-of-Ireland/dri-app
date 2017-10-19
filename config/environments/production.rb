ENV["RAILS_RELATIVE_URL_ROOT"] = "/"
DriApp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # the following might fail for high_voltage
  config.content_path = ENV["RAILS_RELATIVE_URL_ROOT"]

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  Rails.application.routes.default_url_options[:host] = "repository.dri.ie"

  config.exceptions_app = self.routes

  config.action_controller.relative_url_root = '/'

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_files = false

  # Compress JavaScripts and CSS
  config.assets.js_compressor  = :uglifier
  config.assets.css_compressor = :sass

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use syslog
  config.gem 'syslog-logger'
  config.logger = Logger::Syslog.new

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )
  config.assets.precompile += %w( jquery-xmleditor/vendor/cycle.js iiif_viewer.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')].sort
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Add a default host for devise mailer
  config.action_mailer.default_url_options = { protocol: 'https', host: 'repository.dri.ie' }

  config.action_mailer.delivery_method = :sendmail

  #config.middleware.use '::Rack::Auth::Basic' do |u, p|
  #  [u, p] == ['navr', 'navr']
  #end
  # The vjs entries are specified in the Video-JS docs to be included in the production.rd configuration - unsure if this is the right way to pass them in though {EK]}
  config.assets.precompile += [%w( video-js.swf vjs.eot vjs.svg vjs.ttf vjs.woff ),'dri/dri_grid.css','dri/dri_layouts.css']

  # google analytics
  # GA.tracker = 

  Devise.setup do |config|
    config.omniauth_path_prefix = "/users/auth"
  end

  config.eager_load = true

end
