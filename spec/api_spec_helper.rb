require 'rails_helper'
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

RspecApiDocumentation.configure do |config|
  config.api_name = "API Documentation"
  config.api_explanation = "DRI JSON API"
  config.docs_dir = Rails.root.join("doc", "api")
end
