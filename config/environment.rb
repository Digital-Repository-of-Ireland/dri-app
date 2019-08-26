# Load the Rails application.
require_relative 'application'

Mime::Type.register "application/rdf+xml", :rdf
Mime::Type.register "text/turtle", :ttl

# Initialize the Rails application.
Rails.application.initialize!
