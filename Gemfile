# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'blacklight', '4.0.0'
gem 'hydra-head', '5.2.0'

if ENV['DRI_BUNDLE_ENV'] == "tchpc"
  gem 'dri_data_models', :git => 'ssh://git@lonsdale.tchpc.tcd.ie/navr/dri_data_models'
else
  gem 'dri_data_models', :git => 'git@dev.forasfeasa.ie:dri_data_models.git'
end

gem 'rails_config'
gem 'sqlite3'

# Devise authentication, and devise-i18n-views to support localisation of the
# devise forms
gem 'devise'
gem 'devise-i18n-views'

gem 'noid', '0.5.5'

# File processing gems
gem 'mimemagic'

# Language and translation related gems
gem 'http_accept_language'

gem 'jquery-rails'
gem 'jquery-ui-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  # gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'capybara-webkit'
  gem 'headless'
  gem 'jettywrapper'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'railroady'

  # guard - autorun of tests during development cycle
  gem 'guard'
  gem 'guard-cucumber'
  gem 'guard-spork'
  gem 'guard-bundler'
  gem 'guard-yard'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false 
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'launchy'
  gem 'shoulda'
  gem 'factory_girl_rails'
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

gem "devise-guests", "~> 0.3"
gem "bootstrap-sass"
gem "yard"

group :translations do
  gem 'i18n_sync'
end
