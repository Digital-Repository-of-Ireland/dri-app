module BackgroundTasks

    class QueueManager

      require 'background_tasks/workers/ingest_job'
      require 'background_tasks/queue'

      # Set up the ingest process for an object
      #
      # Takes an object as a parameter
      # Uses Resque to enqueue an ingest job.
      # Required ingest tasks for each object type are stored in config/settings.yml
      # Workers to do the work are in lib/background_tasks/workers
      # 
      def process(object)

        pid = object.pid
        Queue.run_in_background(IngestJob, pid)

      end

    end
end
