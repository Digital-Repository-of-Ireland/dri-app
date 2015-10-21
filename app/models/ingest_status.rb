class IngestStatus < ActiveRecord::Base
  has_many :job_status

  PDF_JOBS = %w(text thumbnail)
  TEXT_JOBS = %w(text)
  AUDIO_JOBS = %w(derivatives)
  VIDEO_JOBS = %w(derivatives)
  IMAGE_JOBS = %w(thumbnail)

  def completed?(job_status)
    if (job_status.job == 'characterize' || job_status.job == 'create_bucket') && job_status.status == 'failed'
      self.status = 'error'
      save
    elsif asset_type && job_names.sort == IngestStatus.const_get("#{asset_type}_jobs".upcase).sort
      self.status = completed_status
      save
    end
  end

  def completed_status
    job_status.where(status: 'failed').present? ? 'error' : 'success'
  end

  def job_names
    jobs = job_status.map { |j| j.job }
    jobs.delete_if { |name| %w(characterize create_bucket).include?(name) }
  end
end
