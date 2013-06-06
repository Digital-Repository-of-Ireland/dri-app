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

    # set some status to ingesting?

    @object = ActiveFedora::Base.find(object_id,{:cast => true})

    type = @object.class.name.demodulize.downcase

    if Settings.queue[type]
      Settings.queue[type].each do |task|
        task.constantize.perform(object_id)

        # fail on failure?
        # status to failed?
      end
    end

    # set some status to completed?

  end

end
