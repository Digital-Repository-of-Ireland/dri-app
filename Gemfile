# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'blacklight', '4.0.0'
gem 'hydra-head', '5.2.0'

if ENV['DRI_BUNDLE_ENV'] == "tchpc"
  gem 'dri_data_models', :git => 'ssh://git@lonsdale.tchpc.tcd.ie/navr/dri_data_models'
  gem 'user_group', :git => 'ssh://git@lonsdale.tchpc.tcd.ie/navr/user_group'
else
  gem 'dri_data_models', :git => 'git@dev.forasfeasa.ie:dri_data_models.git'
  gem 'user_group', :git => 'git@dev.forasfeasa.ie:user_group.git'
end

gem 'rails_config'
gem 'sqlite3'

gem 'noid', '0.5.5'

# File processing gems
gem 'mimemagic'

# Language and translation related gems
gem 'http_accept_language'
gem 'it'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-cookie-rails'

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
  gem 'show_me_the_cookies'

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
