require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

RspecApiDocumentation.configure do |config|
  config.api_name = "DRI JSON API"
  config.api_explanation = "API DOCUMENTATION"
  config.docs_dir = Rails.root.join("doc", "api")
  config.format = :JSON
end
