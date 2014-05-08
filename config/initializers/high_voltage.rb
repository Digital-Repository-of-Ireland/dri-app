HighVoltage.configure do |config|
      if ENV['RAILS_ENV'] == 'production'
        config.content_path = 'pages/'
      end
end
