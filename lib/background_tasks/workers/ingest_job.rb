class IngestJob

  require 'background_tasks/workers/verify_audio.rb'
  require 'background_tasks/workers/verify_pdf.rb'
  require 'background_tasks/workers/create_checksums.rb'
  require 'background_tasks/workers/create_ogg.rb'
  require 'background_tasks/workers/create_mp3.rb'
  require 'background_tasks/workers/full_text_index.rb'

  @queue = "ingest_job_queue"

  # Perform the ingest tasks for an object
  #
  # Takes an object id as a parameter
  # Required tasks for each type are stored in config/settings.yml
  # Workers to do the work are in lib/background_tasks/workers
  #
  def self.perform(object_id)
    puts "Ingesting #{object_id} "

    @object = ActiveFedora::Base.find(object_id,{:cast => true})

    initial_status = @object.status

    set_status("processing")
    
    type = @object.class.name.demodulize.downcase

    if Settings.queue[type]
      Settings.queue[type].each do |task|
        task.constantize.perform(object_id)

        # status to failed?
      end
    end

    set_status(initial_status)

  end

  def self.set_status(status)
    @object.status = status
    @object.save
  end

end
