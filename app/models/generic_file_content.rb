class GenericFileContent
  include ActiveModel::Model

  attr_accessor :object, :generic_file, :user

  def add_content(file_upload, path='content')
    set = set_content(file_upload[:file_upload], file_upload[:filename], file_upload[:mime_type], path)
    return set if set == false

    preserve_file(file_upload, path, false)
  end

  def update_content(file_upload, path='content')
    @name_of_file_to_replace = generic_file.label

    set = set_content(file_upload[:file_upload], file_upload[:filename], file_upload[:mime_type], path)
    return set if set == false

    preserve_file(file_upload, path, true)
  end

  def set_content(file, filename, mime_type, path='content')
    # Update object version
    object.object_version ||= 1
    object.increment_version

    begin
      object.save!
    rescue ActiveRecord::RecordNotSaved
      logger.error "Could not update object version number for #{object.noid} to version #{object.object_version}"
      raise Exceptions::InternalError
    end

    generic_file.add_file(file, { path: path, file_name: "#{generic_file.noid}_#{filename}", mime_type: mime_type })
    generic_file.label = filename
    generic_file.title = [filename]

    save_and_characterize
  end

  private

  def preserve_file(filedata, datastream, update=false)
    filename = "#{generic_file.noid}_#{filedata[:filename]}"

    # Do the preservation actions
    addfiles = [filename]
    delfiles = []
    delfiles = ["#{generic_file.noid}_#{@name_of_file_to_replace}"] if update

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets(addfiles, delfiles)
  end

  # Takes an optional block and executes the block if the save was successful.
  def save_and_characterize
    save_with_retry { push_characterize_job }.tap do |val|
      yield if block_given? && val
    end
  end

  # Takes an optional block and executes the block if the save was successful.
  # returns false if the save was unsuccessful
  def save_with_retry
    save_tries = 0
    begin
      return false unless generic_file.save
    rescue RSolr::Error::Http => error
      logger.warn "save_with_retry Caught RSOLR error #{error.inspect}"
      save_tries += 1
      # fail for good if the tries is greater than 3
      raise error if save_tries >= 3
      sleep 0.01
      retry
    end
    yield if block_given?

    true
  end

  def push_characterize_job
    DRI.queue.push(CharacterizeJob.new(generic_file.noid))
  end
end
