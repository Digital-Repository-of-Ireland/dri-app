# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
use Yabeda::Prometheus::Exporter if defined? Yabeda
run DriApp::Application
