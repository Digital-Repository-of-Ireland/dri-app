HighVoltage.configure do |config|
      if ENV['RAILS_ENV'] == 'production'
        config.content_path = 'v1/'
      end
end
