HighVoltage.configure do |config|
      if ENV['RAILS_ENV'] == 'production'
        config.content_path = '00D9DB5F-0CC1-4AE1-B014-968AFA0371AC/pages/'
      end
end
