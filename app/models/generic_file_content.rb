class GenericFileContent
  include ActiveModel::Model

  attr_accessor :object, :generic_file, :user

  def add_content(file_upload, path='content')
    preserve_file(file_upload, path, false)
  end

  def update_content(file_upload, path='content')
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

  def set_content(file, filename, mime_type, path='content', version)
    generic_file.add_file(file, { version: version, path: path, file_name: "#{generic_file.noid}_#{filename}", mime_type: mime_type })
    generic_file.label = filename
    generic_file.title = [filename]
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

    #save_object
    object.object_version ||= 1
    object.increment_version

    set_content(
      filedata[:file_upload],
      filedata[:filename],
      filedata[:mime_type],
      datastream,
      object.object_version
    )

    save_and_characterize

    changes = {}
    # Do the preservation actions
    if update && filedata[:filename] == generic_file.label
      # existing file content is being replaced
      changes[:modified] = { 'content' => [generic_file.path] }
    else
      changes[:added] = {'content' => [generic_file.path]}
      changes[:deleted] = if update
                            {'content' => ["#{generic_file.noid}_#{generic_file.label}"] }
                          else
                            { 'content' => [] }
                          end
    end

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets(changes)
  end

  def save_and_characterize
    return false unless generic_file.save
    push_characterize_job

    true
  end

  def push_characterize_job
    DRI.queue.push(CharacterizeJob.new(generic_file.noid))
  end
end
