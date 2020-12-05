class GenericFileContent
  include ActiveModel::Model

  attr_accessor :object, :generic_file, :user

  def add_content(file_upload, path='content')
    save_object
    set = set_content(file_upload[:file_upload], file_upload[:filename], file_upload[:mime_type], path)
    return set if set == false

    preserve_file(file_upload, path, false)
  end

  def update_content(file_upload, path='content')
    @name_of_file_to_replace = generic_file.label

    save_object
    set = set_content(file_upload[:file_upload], file_upload[:filename], file_upload[:mime_type], path)
    return set if set == false

    preserve_file(file_upload, path, true)
  end

  def save_object
    # Update object version
    object.object_version ||= 1
    object.increment_version

    begin
      object.save!
    rescue ActiveRecord::RecordNotSaved
      logger.error "Could not update object version number for #{object.noid} to version #{object.object_version}"
      raise Exceptions::InternalError
    end
  end

  def set_content(file, filename, mime_type, path='content')
    generic_file.add_file(file, { path: path, file_name: "#{generic_file.noid}_#{filename}", mime_type: mime_type })
    generic_file.label = filename
    generic_file.title = [filename]

    save_and_characterize
  end

  private

  def existing_moab_path(file_category, filename, filepath)
    preservation = Preservation::Preservator.new(object)
    preservation.existing_filepath(
                                    file_category,
                                    "#{generic_file.noid}_#{filename}",
                                    filepath
                                  )
  end

  def preserve_file(filedata, datastream, update=false)
    filename = "#{generic_file.noid}_#{filedata[:filename]}"    

    moab_path = existing_moab_path(
                                    datastream,
                                    filedata[:filename],
                                    filedata[:file_upload].path
                                  )

    # attempting to replace existing file with duplicate
    if moab_path && filedata[:filename] == generic_file.label
      raise DRI::Exceptions::MoabError, "File already preserved"
    end

    # Update object version
    object.object_version ||= '1'
    object.increment_version

    begin
      object.save!
    rescue ActiveFedora::RecordInvalid
      logger.error "Could not update object version number for #{object.noid} to version #{object.object_version}"
      raise Exceptions::InternalError
    end

    changes = {}
    # Do the preservation actions
    if update && filedata[:filename] == generic_file.label
      # existing file content is being replaced
      changes[:modified] = { 'content' => [@file.path] }
    else
      changes[:added] = {'content' => [@file.path]}
      changes[:deleted] = if update
                            {'content' => ["#{generic_file.noid}_#{generic_file.label}"] }
                          else
                            { 'content' => [] }
                          end
    end

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets(changes)
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
