module BackgroundTasks
    class QueueManager

      require 'resque'
      require 'background_tasks/workers/verify_audio.rb'
      require 'background_tasks/workers/verify_pdf.rb'
      require 'background_tasks/workers/virus_scan.rb'
      require 'background_tasks/workers/create_checksums.rb'
      require 'background_tasks/workers/create_ogg.rb'
      require 'background_tasks/workers/create_mp3.rb'
      require 'background_tasks/workers/full_text_index.rb'

      # Set up the background tasks for an Audio object
      #
      # Takes a process id as a parameter
      # Uses Resque to enqueue each of the required jobs for that object
      # type.
      # Reqiured jobs for each type are stored in config/settings.yml
      # Workers to process the queues and do the work are in lib/background_tasks/workers
      # 
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


      # Set up the background tasks for a PDF object
      #
      # Takes a process id as a parameter
      # Uses Resque to enqueue each of the required jobs for that object
      # type.
      # Reqiured jobs for each type are stored in config/settings.yml
      # Workers to process the queues and do the work are in lib/background_tasks/workers
      # 
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
