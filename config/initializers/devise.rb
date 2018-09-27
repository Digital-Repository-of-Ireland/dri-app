Devise.setup do |config|
  config.warden do |manager|
    manager.failure_app = CustomDeviseFailureApp
  end
end
