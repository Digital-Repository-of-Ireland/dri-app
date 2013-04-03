module BackgroundTasks
    class QueueManager

      require 'resque'
      require 'background_tasks/workers/create_surrogates'

      def process_audio(pid)

        begin
          raise Exceptions::InternalError unless Resque.enqueue(CreateSurrogates, pid)
        rescue Redis::CannotConnectError => e
          logger.error "Could not connect to redis: #{e.message}"
          raise Exceptions::InternalError
        end

      end

    end
end
