HighVoltage.configure do |config|
  config.routes = false
  config.content_path = 'pages/' if Rails.env.production?
end
