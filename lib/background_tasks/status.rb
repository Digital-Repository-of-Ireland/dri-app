module BackgroundTasks
  module Status

    def status
      @status ||= IngestStatus.find_or_create_by(asset_id: generic_file_id) do |ingest_status|
        ingest_status.batch_id = generic_file.digital_object.noid
        ingest_status.status = 'processing'
      end

      if @status.status == 'success'
        @status.status = 'processing'
        @status.job_status.each { |j| j.delete }
        @status.save
      end

      @status
    end 

    def with_status_update(job)
      create_job_status(job)
      status.job_status << @job_status
      status.save

      begin
        yield

        success
      rescue => e
        Rails.logger.error "Error in #{job} background task for #{generic_file_id}: #{e.message}"
        failed(e.message)
      end
    end

    def create_job_status(job)
      @job_status = JobStatus.create(job: job, status: 'processing')
    end

    def failed(message)
      @job_status.status = 'failed'
      @job_status.message = message
      @job_status.save

      status.completed?(@job_status)
    end

    def status_for_type(type)
      status.asset_type = type
      status.save
    end

    def success
      @job_status.status = 'success'
      @job_status.save

      status.completed?(@job_status)
    end
  end
end
