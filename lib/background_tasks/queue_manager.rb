module BackgroundTasks
    class QueueManager

      require 'resque'
      require 'background_tasks/workers/verify_audio.rb'
      require 'background_tasks/workers/verify_pdf.rb'
      require 'background_tasks/workers/virus_scan.rb'

      def process_audio(pid)

        Settings.queue.audio.each do |task|
          begin
            raise Exceptions::InternalError unless Resque.enqueue(task.constantize, pid)
          rescue Redis::CannotConnectError => e
            logger.error "Could not connect to redis: #{e.message}"
            raise Exceptions::InternalError
          rescue Resque::NoQueueError => e
            logger.error "Invalid Resque queue: #{task} #{e.message}"
            raise Exceptions::InternalError
          end
        end

      end


      def process_article(pid)

        Settings.queue.pdfdoc.each do |task|
          begin
            raise Exceptions::InternalError unless Resque.enqueue(task.constantize, pid)
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
end
