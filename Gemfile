# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

gem 'rails', '~> 6.1'

gem 'blacklight', '~>7'
gem 'blacklight_advanced_search', '~> 7'
gem 'view_component', '2.74.1'
gem 'blacklight_oai_provider', github: 'projectblacklight/blacklight_oai_provider' #'~> 6'
gem 'rsolr'
gem 'kaminari', '>= 1.2.1'

gem 'hydra-derivatives', git: 'https://github.com/Digital-Repository-of-Ireland/hydra-derivatives.git', branch: 'main'
gem 'om', '3.2.0'
gem 'solrizer'
gem 'nokogiri', '>= 1.13.9'

gem 'riiif'
gem 'iiif-presentation', git: 'https://github.com/IIIF/osullivan.git'
gem 'openseadragon'

gem 'dri_data_models', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-data-models.git', branch: 'develop'
gem 'user_group', git: 'ssh://git@tracker.dri.ie:2200/drirepo/dri-user-group.git', branch: 'develop'
gem "devise", ">= 4.7.1"

gem 'paper_trail'

gem 'linkeddata'

gem 'aws-sdk-s3', '1.116.0'

# batch ingest
gem 'dri_batch_ingest', git: 'https://github.com/Digital-Repository-of-Ireland/dri-batch-ingest', branch: 'main'
gem 'browse-everything', '~> 1.1.0' 
gem 'avalon_ingest', git: 'https://github.com/stkenny/avalon_ingest'
gem 'roo'
gem 'jstree-rails-4', git: 'https://github.com/kesha-antonov/jstree-rails-4'

gem 'config'
gem 'sqlite3'
gem 'omniauth', '~> 1.9.1'
gem 'omniauth-shibboleth'
gem "omniauth-rails_csrf_protection"
gem 'oauth'

#gem 'feedjira'

# Storage-related gems
gem 'moab-versioning', '~> 4.4'
gem 'valkyrie', '~> 2.2'
gem 'bagit'

gem 'redis', '~> 4'

# File processing gems
gem "image_processing", ">= 1.12.2"

# Language and translation related gems
gem 'http_accept_language'
gem 'it'
gem 'i18n-tasks'
gem 'i18n-js'

# Citations
gem 'citeproc-ruby'
gem 'csl-styles'
gem 'gender_detector'

# logging
gem 'syslog-logger'

gem 'jquery-rails'
gem 'jquery-ui-sass-rails'
gem 'js_cookie_rails'

# clients
gem 'rest-client', '~> 2.0'
gem 'sparql-client'
gem 'httparty'

# static pages
gem 'high_voltage', '~> 3.1'

# monitoring
# is it working fork
gem 'is_it_working-cbeer'
gem 'resque'
gem 'resque-status', '0.5.0'
gem 'nest'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs', '2.7.0'

gem 'uglifier', '>= 1.0.3'

group :production do
  gem 'clamby'
  gem 'mysql2' 
  gem 'honeybadger'
end

group :development, :test do
  gem 'thin'
  gem 'bixby', '~> 3'
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'rswag-specs'
  gem 'rspec_junit_formatter'
  gem 'webdrivers'
  gem 'simplecov', require: false
  gem 'railroady'
  gem 'show_me_the_cookies'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'ci_reporter_rspec'
  gem 'solr_wrapper', '>= 0.3'
  gem 'fcrepo_wrapper', '0.9.0'
  gem 'byebug', '~> 10.0'
  gem 'parallel_tests', '~> 2.23'
  #gem 'i18n-debug', '~> 1.2'
  gem 'yard'
  gem 'listen'
  gem 'sane_patch', '~> 1.0'
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
gem 'bootstrap-sass', '~> 3.4.1'
#gem 'bootstrap', "~> 4.0"
gem 'bootstrap-glyphicons'
gem 'sassc-rails', '>= 2.1.0'
gem 'sass-rails', '5.1.0'

group :translations do
  gem 'i18n_sync'
end

# analytics
gem 'legato'
gem 'google-oauth2-installed'
gem 'rack-tracker'

gem 'rvm'

# UI widgets
gem 'jquery-colorbox-rails'
gem 'bootstrap-switch-rails'
gem 'timelineJS3-rails', git: 'https://github.com/stkenny/timelineJS3-rails.git'
gem 'openlayers-rails'
gem 'jquery-xmleditor-rails', git: 'https://github.com/stkenny/jquery-xmleditor-rails.git', branch: 'form_upload'
gem 'clipboard-rails'

gem 'blacklight-maps', '> 0.5'

gem 'jquery-datatables', git: 'https://github.com/stkenny/jquery-datatables.git'
gem 'jquery-slick-rails'
gem 'remotipart'

# # api documentation generator / presenter
gem 'rswag-api', '~> 2.0'
gem 'rswag-ui', '~> 2.0'

# authorities
gem 'qa', '~> 5.1'

gem "seedbank", "~> 0.5.0"
