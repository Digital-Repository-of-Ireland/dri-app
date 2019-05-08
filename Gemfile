# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

gem 'rails', '>= 4', '< 5'
# fix rails dependency problem
#gem 'sinatra'#, '1.4.8'
#gem 'xmlrpc' # removed in ruby 2.4.0

gem 'blacklight', '~> 6'
gem 'blacklight_oai_provider', git: 'https://github.com/Digital-Repository-of-Ireland/blacklight_oai_provider.git'
gem 'tzinfo-data'

gem 'hydra-head', '~> 10.6'

gem 'riiif', '1.2.0'
gem 'iiif-presentation', git: 'https://github.com/IIIF/osullivan.git'
gem 'openseadragon'

gem 'dri_data_models', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-data-models.git', tag: 'v3.0.0'
gem 'user_group', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-user-group.git', tag: 'v1.3.0'
gem 'paper_trail', '~> 4'

# batch ingest
gem 'dri_batch_ingest', git: 'https://github.com/Digital-Repository-of-Ireland/dri-batch-ingest.git', tag: 'v1.0.2'
gem 'browse-everything', '1.0.0'
gem 'avalon_ingest', git: 'https://github.com/stkenny/avalon_ingest'
gem 'roo', '2.6.0'

gem 'config'
gem 'sqlite3','~> 1.3', '< 1.4'

gem 'omniauth-shibboleth'
gem 'oauth'

#gem 'feedjira'

# Storage-related gems
gem 'moab-versioning'

# File processing gems
gem 'mimemagic'

# Language and translation related gems
gem 'http_accept_language'
gem 'it'
gem 'i18n-tasks' #, '~> 0.9.15'
gem 'i18n-js'

# logging
gem 'syslog-logger'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'js_cookie_rails'

# clients
gem 'rest-client', '~> 2.0'
gem 'sparql-client', '~> 1.99'
gem 'httparty'

# static pages
gem 'high_voltage', '~> 2.1.0'

# monitoring
# is it working fork
gem 'is_it_working-cbeer'
gem 'resque'
gem 'resque-status'
gem 'nest'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'

gem 'uglifier', '>= 1.0.3'

group :production do
  gem 'clamav'
  gem 'mysql2', '< 0.5'
  gem 'honeybadger', '~> 2.0'
end

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'rspec_junit_formatter'
  gem 'webdrivers'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'railroady'
  gem 'show_me_the_cookies'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'ci_reporter_rspec'
  gem 'solr_wrapper', '~> 0.18'
  gem 'fcrepo_wrapper', '0.9.0'
  gem 'byebug', '~> 10.0'
  gem 'parallel_tests', '~> 2.23'
  gem 'puffing-billy', '~> 0.11.0'
  gem 'yard'
end

group :test do
  # requires >= 3.3.0 to test styles on node element
  # https://github.com/teamcapybara/capybara/commit/faa45e135434a7f16f04ef5136c63a0663925dec
  gem 'capybara', '~> 3.14'
  gem 'cucumber', '~> 3.1'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'launchy'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'syntax'
  gem 'cucumber-api-steps'
  gem 'shoulda', '~> 3.6'
  gem 'shoulda-matchers'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
#gem 'unicorn'

# To use debugger
#gem 'debugger'

gem 'unicode', platforms: [:mri_18, :mri_19]
gem 'font-awesome-rails'
gem 'jwt', '1.5.2'
gem 'bootstrap-sass', '3.4.1'
gem 'bootstrap-glyphicons'
gem 'sass-rails', '~> 4.0.4'

group :translations do
  gem 'i18n_sync'
end

# analytics
gem 'google-analytics-rails', '1.1.0'
gem 'gabba'
gem 'legato'
gem 'google-oauth2-installed'

gem 'rvm'

# UI widgets
gem 'colorbox-rails'
gem 'bootstrap-switch-rails'
gem 'timelineJS3-rails', git: 'https://github.com/stkenny/timelineJS3-rails.git'
gem 'openlayers-rails'
gem 'social-share-button'
gem 'jquery-xmleditor-rails', git: 'https://github.com/stkenny/jquery-xmleditor-rails.git', branch: 'form_upload'
gem 'clipboard-rails'

gem 'blacklight-maps'
gem 'leaflet-rails', '1.0.0'
gem 'rails-assets-leaflet', '1.1.0', source: 'https://rails-assets.org'
gem 'rails-assets-leaflet.markercluster', '1.3.0', source: 'https://rails-assets.org'

gem 'jquery-datatables', git: 'https://github.com/stkenny/jquery-datatables.git'
gem 'jquery-slick-rails'
gem 'remotipart'

# # api documentation generator / presenter
gem 'rswag-api', '~> 2.0'
gem 'rswag-ui', '~> 2.0'

# authorities
gem 'qa', '~> 1.2'
gem 'rdf', '~> 1.99'
gem 'rdf-vocab', '~> 0.8.8'

gem "seedbank", "~> 0.5.0"
