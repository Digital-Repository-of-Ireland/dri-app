module BackgroundTasks
  module Status

    def status
      @status ||= IngestStatus.where(asset_id: generic_file_id).first
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
