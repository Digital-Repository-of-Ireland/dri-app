module BackgroundTasks
    class QueueManager

      require 'resque'

      require 'background_tasks/workers/ingest_job.rb'

      # Set up the ingest process for an object
      #
      # Takes an object as a parameter
      # Uses Resque to enqueue an ingest job.
      # Required ingest tasks for each object type are stored in config/settings.yml
      # Workers to do the work are in lib/background_tasks/workers
      # 
      def process(object)

        pid = object.pid

        begin
          raise Exceptions::InternalError unless Resque.enqueue(IngestJob, pid)
        rescue Redis::CannotConnectError => e
          logger.error "Could not connect to redis: #{e.message}"
          raise Exceptions::InternalError
        rescue Resque::NoQueueError => e
          logger.error "Invalid Resque queue: #{e.message}"
          raise Exceptions::InternalError
        end

      end

    end
end
