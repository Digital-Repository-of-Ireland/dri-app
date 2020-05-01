class CreateDerivativesJob < ActiveFedoraIdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :derivatives
  end

  def run
    with_status_update('create_derivatives') do
      generic_file.create_derivatives(generic_file.label)
    end
  end
end
