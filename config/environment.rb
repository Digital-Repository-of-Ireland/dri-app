# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
DriApp::Application.initialize!

Mime::Type.register "application/rdf+xml", :rdf
Mime::Type.register "text/turtle", :ttl
