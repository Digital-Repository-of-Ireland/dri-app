# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'http://rubygems.org'

gem 'rails','~> 4.2'

gem 'blacklight', '~> 5.16.0'
gem 'blacklight_range_limit'
gem 'blacklight-maps'
gem 'hydra-head', '9.6.0'

gem 'sufia-models', '6.5.0'
gem 'redlock'
gem 'google-api-client', '0.8.6'

gem 'paper_trail', '~> 4'

gem 'dri_data_models', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-data-models.git', branch: 'develop'
gem 'user_group', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-user-group.git', branch: 'develop'

gem 'active-fedora', '~> 9.7'
gem 'active_fedora-noid', '1.0.3'

gem 'rails_config'
gem 'sqlite3'
gem 'mysql'
gem 'mysql2'

gem 'omniauth-shibboleth'
gem 'oauth'

gem 'feedjira'

# Storage-related gems
gem 'aws-sdk', '~> 2'

#gem 'clamav'

# File processing gems
gem 'mimemagic'

# Language and translation related gems
gem 'http_accept_language'
gem 'it'

# logging
gem 'syslog-logger'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-cookie-rails'

gem 'remotipart'

gem 'rest-client'
gem 'sparql-client'

# static pages
gem 'high_voltage', '~> 2.1.0'

# is it working fork
gem 'is_it_working-cbeer'

gem 'sass-rails' , '~> 4.0.4'
gem 'compass-rails'
# gem 'coffee-rails', '~> 3.2.1'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'

gem 'uglifier', '>= 1.0.3'

group :development, :test do
  gem 'guard'
  gem 'rspec-rails', '~> 2.99'
  gem 'poltergeist', '>= 1.4.1'
  gem 'jettywrapper'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'railroady'
  gem 'show_me_the_cookies'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard-livereload', require: false
  gem 'compass'

  gem "zeus", require: false

  gem 'ci_reporter_cucumber'
  gem 'ci_reporter_rspec'
  gem 'fakes3', git: 'ssh://git@tracker.dri.ie:2200/drirepo/fake-s3.git', branch: 'issue22'
end

group :test do
  gem 'cucumber', '1.3.15'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'launchy'
  gem 'shoulda'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'syntax'
  gem 'cucumber-api-steps'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# To use debugger
# gem 'debugger'

gem 'unicode', platforms: [:mri_18, :mri_19]
gem 'font-awesome-rails'
gem 'bootstrap-sass' #, '~> 3.3.4'
gem 'yard'

group :translations do
  gem 'i18n_sync'
end

# analytics
gem 'google-analytics-rails'

gem 'rvm'

# UI widgets
gem 'colorbox-rails'
gem 'bootstrap-switch-rails'
gem 'videojs_rails', git: 'https://github.com/ekilfeather/videojs_rails.git', ref: '605afa19acc03c4e7a1fc7a4031fa6a3311ffdcd'
gem 'timelineJS-rails', '~> 1.1.5'
gem 'openlayers-rails'
gem 'social-share-button'
