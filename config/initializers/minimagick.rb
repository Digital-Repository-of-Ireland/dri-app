require 'mini_magick'

MiniMagick.configure do |config|
  config.logger = Rails.logger
  config.logger.level = Logger::DEBUG
end
