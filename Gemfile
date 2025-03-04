# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

gem 'rails', '> 6', '< 7.2'
gem 'uri', '~> 0.13.2'

gem 'blacklight', '7.38.0'
gem 'blacklight_advanced_search', '~> 7'
gem 'blacklight_oai_provider', '~> 7.0', '>= 7.0.2'
gem 'kaminari', '>= 1.2.1'
gem 'rsolr'
gem 'view_component', '< 3'

gem 'hydra-derivatives', git: 'https://github.com/Digital-Repository-of-Ireland/hydra-derivatives.git', branch: 'af_optional'
gem 'nokogiri', '>= 1.16.5'
gem 'om', git: 'https://github.com/Digital-Repository-of-Ireland/om.git', branch: 'master'
gem 'solrizer'

gem 'iiif-presentation'
gem 'openseadragon'
gem 'riiif'

gem "devise", ">= 4.7.1"
gem 'dri_data_models', git: 'git@github.com:Digital-Repository-of-Ireland/dri-data-models.git', branch: 'develop'
gem 'user_group', git: 'git@github.com:Digital-Repository-of-Ireland/dri-user-group.git', branch: 'develop'

gem 'paper_trail'

gem 'linkeddata'

# batch ingest
gem 'avalon_ingest', git: 'https://github.com/stkenny/avalon_ingest'
gem 'browse-everything'#, '~> 1.2.0'
gem 'dri_batch_ingest', git: 'https://github.com/Digital-Repository-of-Ireland/dri-batch-ingest', branch: 'main'
gem 'jstree-rails-4', git: 'https://github.com/kesha-antonov/jstree-rails-4'
gem 'roo'

gem 'config'
gem 'oauth'
gem 'omniauth', '~> 2'
gem "omniauth-rails_csrf_protection"
gem 'omniauth-shibboleth'
gem 'sqlite3'

# Storage-related gems
gem 'bagit'
gem 'moab-versioning', '~> 4.4', '>= 4.4.2'

gem 'redis', '~> 4'

# File processing gems
gem "image_processing", ">= 1.12.2"

# Language and translation related gems
gem 'http_accept_language'
gem 'i18n-js', '< 4'
gem 'i18n-tasks'
gem 'it'

# Citations
gem 'citeproc-ruby'
gem 'csl-styles'
gem 'gender_detector'

# logging
gem 'syslog-logger'

gem 'jquery-rails'
gem 'jquery-ui-rails-dox-fork', require: "jquery-ui-rails"
gem 'js_cookie_rails'

# clients
gem 'httparty', '>= 0.21.0'
gem 'rest-client', '~> 2.0'
gem 'sparql-client'

# static pages
gem 'high_voltage', '~> 3.1'

# monitoring
# is it working fork
gem 'is_it_working-cbeer'
gem 'nest'
gem 'resque'

group :development, :production do
  gem 'appsignal'
end

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs', '2.7.0'
gem 'terser'

group :production do
  gem 'clamby'
  gem 'honeybadger'
  gem 'mysql2'
end

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bixby', '~> 5'
  gem 'dotenv-rails'
  gem 'railroady'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails', '~> 6'
  gem 'rswag-specs'
  gem 'selenium-webdriver'
  gem 'show_me_the_cookies'
  gem 'simplecov', require: false
  gem 'thin'
  # gem 'ci_reporter_rspec'
  gem 'byebug', '~> 10.0'
  gem 'fcrepo_wrapper', '0.9.0'
  gem 'parallel_tests'
  gem 'solr_wrapper', '>= 0.3'
  # gem 'i18n-debug', '~> 1.2'
  gem 'listen'
  gem 'sane_patch', '~> 1.0'
  gem 'yard'
end

group :test do
  # requires >= 3.3.0 to test styles on node element
  # https://github.com/teamcapybara/capybara/commit/faa45e135434a7f16f04ef5136c63a0663925dec
  gem 'capybara', '~> 3.14'
  gem 'cucumber', '~> 3.1'
  gem 'cucumber-api-steps'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'launchy'
  gem 'shoulda', '~> 3.6'
  gem 'shoulda-matchers'
  gem 'syntax'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'

gem 'bootstrap', '5.3.2'
gem 'bootstrap-glyphicons'
gem 'font-awesome-sass', "~> 6.7.2"
gem 'jwt', '1.5.2'
gem 'unicode', platforms: [:mri_18, :mri_19]

group :translations do
  gem 'i18n_sync'
end

# analytics
gem 'faraday'
gem 'faraday_middleware'
gem 'google-analytics-data-v1beta', '~> 0.8.0'
gem 'google-oauth2-installed'
gem 'legato'

gem 'rvm'

# UI widgets
gem 'bootstrap-switch-rails'
gem 'clipboard-rails'
gem 'jquery-xmleditor-rails', git: 'https://github.com/stkenny/jquery-xmleditor-rails.git', branch: 'form_upload'
gem 'openlayers-rails'
gem 'timelineJS3-rails', git: 'https://github.com/stkenny/timelineJS3-rails.git'
gem 'blacklight-maps', git: 'https://github.com/Digital-Repository-of-Ireland/blacklight-maps.git', branch: 'rails7'

gem 'remotipart'

# # api documentation generator / presenter
gem 'rswag-api', '~> 2.0'
gem 'rswag-ui', '~> 2.0'

# authorities
gem 'qa', '~> 5.1'

gem "seedbank", "~> 0.5.0"

gem "dartsass-rails", "~> 0.5.0"
gem "dartsass-sprockets"
gem "sprockets", "< 4"

gem "importmap-rails", "1.2.3"
