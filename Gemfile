# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'http://rubygems.org'

gem 'rails', '~> 4.1.0'

gem 'blacklight', "5.5.2"
gem 'hydra-head', "7.1.0"
gem 'sufia-models', "4.0.0rc1"

gem 'dri_data_models', :git => 'ssh://git@tracker.dri.ie/navr/dri_data_models', :branch => 'hydra7'
gem 'user_group', :git => 'ssh://git@tracker.dri.ie/navr/user_group', :branch => 'hydra7'

gem 'rails_config'
gem 'sqlite3'
gem 'mysql'
gem 'mysql2'

gem 'omniauth-shibboleth'
gem 'feedjira'

# Storage-related gems
gem 'aws-sdk'

#gem 'clamav'

# File processing gems
gem 'mimemagic'

# Language and translation related gems
gem 'http_accept_language'
gem 'it'

# logging
gem 'logstash-logger'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-cookie-rails'

gem 'remotipart'

gem 'rest-client'

# static pages
gem 'high_voltage', '~> 2.1.0'

# is it working fork
gem 'is_it_working-cbeer'

gem 'sass-rails' , '~> 4.0.2'
# gem 'coffee-rails', '~> 3.2.1'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'

gem 'uglifier', '>= 1.0.3'

group :development, :test do
  gem 'rspec-rails', '~> 2.99'
  gem 'poltergeist', '>= 1.4.1'
  gem 'jettywrapper'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'railroady'
  gem 'show_me_the_cookies'
  gem 'better_errors'
  gem 'binding_of_caller'

  gem "zeus", require: false

  gem 'ci_reporter'
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_cleaner', '1.0.1'
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

gem "unicode", :platforms => [:mri_18, :mri_19]
gem 'font-awesome-rails'
gem 'bootstrap-sass'
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
gem 'videojs_rails'
