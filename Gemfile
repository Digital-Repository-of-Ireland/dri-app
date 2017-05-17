# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'http://rubygems.org'

gem 'rails','~> 4.2'

gem 'blacklight', '~> 5.19.0'
gem 'blacklight-maps'
gem 'hydra-head', '9.10'

gem 'riiif', git: 'https://github.com/curationexperts/riiif.git'
gem 'iiif-presentation', git: 'https://github.com/IIIF/osullivan.git'
gem 'openseadragon'

gem 'redlock'
gem 'google-api-client', '0.8.6'

gem 'paper_trail', '~> 4'

gem 'dri_data_models', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-data-models.git', tag: 'v2.5.0.1'
gem 'user_group', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-user-group.git', tag: 'v1.2.1'

gem 'active-fedora', '9.11'
gem 'active_fedora-noid', '1.1.1'

gem 'rails_config'
gem 'sqlite3'
gem 'mysql'
gem 'mysql2'

gem 'omniauth-shibboleth'
gem 'oauth'

gem 'feedjira'

# Storage-related gems
gem 'aws-sdk', '~> 2'
gem 'moab-versioning'
gem 'browse-everything', git: 'https://github.com/stkenny/browse-everything.git', branch: 's3_provider'

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
gem 'jquery-datatables', git: 'https://github.com/stkenny/jquery-datatables.git'
gem 'remotipart'

# clients
gem 'rest-client'
gem 'sparql-client'

# static pages
gem 'high_voltage', '~> 2.1.0'

# monitoring 
# is it working fork
gem 'is_it_working-cbeer'
gem 'honeybadger', '~> 2.0'
gem 'resque', '1.26'
gem 'resque-status'
gem 'nest'

gem 'sass-rails' , '~> 4.0.4'
gem 'compass-rails'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'

gem 'uglifier', '>= 1.0.3'

group :production do
  gem 'clamav'
end

group :development, :test do
  gem 'guard'
  gem 'rspec-rails', '~> 3.0'
  gem 'poltergeist', '>= 1.11.0'
  gem 'phantomjs', :require => 'phantomjs/poltergeist'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'railroady'
  gem 'show_me_the_cookies'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard-livereload', require: false
  gem 'compass'

  gem "zeus", require: false

  gem 'ci_reporter_rspec'

  gem 'solr_wrapper', '~> 0.18'
  gem 'fcrepo_wrapper', '0.6.0'

  gem 'fakes3', git: 'ssh://git@tracker.dri.ie:2200/drirepo/fake-s3.git', branch: 'issue22'
end

group :test do
  gem 'cucumber', '2.3.3'
  gem 'cucumber-rails', '1.4.3', require: false
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
gem 'jwt', '1.5.2'
gem 'bootstrap-sass', '~> 3.2'
gem 'bootstrap-glyphicons'
gem 'yard'

group :translations do
  gem 'i18n_sync'
end

# analytics
gem 'google-analytics-rails', '1.1.0'

gem 'rvm'

# UI widgets
gem 'colorbox-rails'
gem 'bootstrap-switch-rails'
gem 'videojs_rails', git: 'https://github.com/ekilfeather/videojs_rails.git', ref: '605afa19acc03c4e7a1fc7a4031fa6a3311ffdcd'
gem 'timelineJS3-rails', git: 'https://github.com/stkenny/timelineJS3-rails.git'
gem 'openlayers-rails'
gem 'social-share-button'
gem 'jquery-xmleditor-rails', git: 'https://github.com/stkenny/jquery-xmleditor-rails.git', branch: 'form_upload'
