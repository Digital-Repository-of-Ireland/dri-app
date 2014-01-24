# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'http://rubygems.org'

gem 'rails', '3.2.13'
gem 'blacklight', '4.5.0'
gem 'hydra-head', '6.4.0'
gem 'sufia-models', '3.4.0'

gem 'dri_data_models', :git => 'ssh://git@tracker.dri.ie/navr/dri_data_models', :branch => 'develop'
#gem 'dri_data_models', :git => 'git@dev.forasfeasa.ie:dri_data_models.git', :branch => 'action424'
gem 'user_group', :git => 'ssh://git@tracker.dri.ie/navr/user_group', :branch => 'develop'

gem 'rails_config'
gem 'sqlite3'
gem 'mysql2'

# Storage-related gems
gem 'aws-s3'

#gem 'clamav'

# File processing gems
gem 'mimemagic'

# Language and translation related gems
gem 'http_accept_language', '~> 1.0.2'
gem 'it'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-cookie-rails'

gem 'remotipart'

gem 'rest-client'

# static pages
gem 'high_voltage', '~> 2.1.0'

# provide feedback to upstream proxy
gem 'rails-pulse'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  # gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'execjs'

  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'poltergeist', '>= 1.4.1'
  gem 'jettywrapper'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'railroady'
  gem 'show_me_the_cookies'
  gem 'better_errors'
  gem 'binding_of_caller'

  # guard - autorun of tests during development cycle
  gem 'guard'
  gem 'guard-cucumber'
  gem 'guard-spork'
  gem 'guard-bundler'
  gem 'guard-yard'
  gem 'guard-compass'
  gem 'guard-livereload'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

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
gem "bootstrap-sass"
gem "yard"

group :translations do
  gem 'i18n_sync'
end

# analytics
gem 'google-analytics-rails'

gem 'rvm'
