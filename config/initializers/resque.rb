require 'resque/job_with_status'

conf_file = File.join(Rails.root, 'config', 'redis.yml')

if File.exists?(conf_file)
  config = YAML::load(File.open(conf_file))[Rails.env]
  Resque.redis = Redis.new(host: config['host'], port: config['port'], password: config['password'])
else
  Resque.redis = "localhost:6379"
end

Resque::Plugins::Status::Hash.expire_in = (24 * 60 * 60)
