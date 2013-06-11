module BackgroundTasks
  module Queue

    require 'resque'

    def self.run_in_background(task, id)
      begin
        raise Exceptions::InternalError unless Resque.enqueue(task, id)
      rescue Redis::CannotConnectError => e
        Rails.logger.error "Could not connect to redis: #{e.message}"
      rescue Resque::NoQueueError => e
        Rails.logger.error "Invalid Resque queue: #{e.message}"
      end
    end

  end
end
