Devise.setup do |config|
  # https://github.com/plataformatec/devise/wiki/Speed-up-your-unit-tests
  config.stretches = Rails.env.test? ? 1 : 10

  config.warden do |manager|
    manager.failure_app = FailureApps::CustomDeviseFailureApp
  end
end
