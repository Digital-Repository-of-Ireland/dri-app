class GenericFileContent
  include ActiveModel::Model

  attr_accessor :generic_file, :user

  def external_content(url, filename, path='content')
    create_content('', filename, path, external_mime_type(url))
  end

  private

  def create_content(file, filename, path, mime_type)
    generic_file.add_file(file, path: path, original_name: filename, mime_type: mime_type)
    generic_file.label = filename
    generic_file.title = [filename]

    save_characterize_and_record_committer
  end

  # Takes an optional block and executes the block if the save was successful.
  def save_characterize_and_record_committer
    save_and_record_committer { push_characterize_job }.tap do |val|
      yield if block_given? && val
    end
  end

  # Takes an optional block and executes the block if the save was successful.
  # returns false if the save was unsuccessful
  def save_and_record_committer
    save_tries = 0
    begin
      return false unless generic_file.save
    rescue RSolr::Error::Http => error
      ActiveFedora::Base.logger.warn "save_and_record_committer Caught RSOLR error #{error.inspect}"
      save_tries += 1
      # fail for good if the tries is greater than 3
      raise error if save_tries >= 3
      sleep 0.01
      retry
    end
    yield if block_given?

    @generic_file.record_version_committer(user)
    true
  end

  def push_characterize_job
    DRI.queue.push(CharacterizeJob.new(generic_file.id))
  end

  def external_mime_type(url)
    "message/external-body; access-type=URL; URL=\"#{url}\""
  end

end
