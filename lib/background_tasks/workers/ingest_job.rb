class IngestJob
  
  require 'background_tasks/workers/verify_audio'
  require 'background_tasks/workers/verify_pdf'
  require 'background_tasks/workers/create_checksums'
  require 'background_tasks/workers/create_ogg'
  require 'background_tasks/workers/create_mp3'
  require 'background_tasks/workers/full_text_index'
  require 'background_tasks/workers/create_bucket'

  require 'background_tasks/queue'

  @queue = "ingest_job_queue"

  # Perform the ingest tasks for an object
  #
  # Takes an object id as a parameter
  # Required tasks for each type are stored in config/settings.yml
  # Workers to do the work are in lib/background_tasks/workers
  #
  def self.perform(object_id)
    Rails.logger.info "Ingesting #{object_id}"

    @object = ActiveFedora::Base.find(object_id,{:cast => true})
    
    type = @object.class.name.demodulize.downcase

    if Settings.queue[type]
      Settings.queue[type].each do |task|
        unless task.is_a?(Array)
          task.constantize.perform(object_id)
        else
          run_in_background(task, object_id)
        end
      end
    end

    Rails.logger.info "Completed processing #{object_id}"
  end

  def self.run_in_background(tasks, object_id)
    tasks.each do |task|
      BackgroundTasks::Queue.run_in_background(task.constantize, object_id)
    end
  end

end
