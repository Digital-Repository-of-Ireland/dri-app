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

      # Set up the background tasks for an object
      #
      # Takes an object as a parameter
      # Uses Resque to enqueue each of the required jobs for that object
      # type.
      # Required jobs for each type are stored in config/settings.yml
      # Workers to process the queues and do the work are in lib/background_tasks/workers
      # 
      def process(object)

        type = object.class.name.demodulize.downcase
        pid = object.pid

        if Settings.queue[type]
          Settings.queue[type].each do |task|
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

      end

    end
end
