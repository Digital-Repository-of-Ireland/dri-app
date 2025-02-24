class GenericFileContent
  include ActiveModel::Model
  include DRI::Citable

  attr_accessor :object, :generic_file, :user

  def add_content(file_upload, path='content')
    preserve_file(file_upload, path, false)
  end

  def update_content(file_upload, path='content')
    preserve_file(file_upload, path, true)
  end

  def set_content(file, filename, mime_type, version, path='content', moab_path=nil)
    options = {
      version: version,
      path: path,
      file_name: "#{generic_file.alternate_id}_#{filename}",
      mime_type: mime_type,
      moab_path: moab_path
    }
    generic_file.add_file(file, options)
    generic_file.label = filename
    generic_file.title = [filename]
    generic_file.index_needs_update = false
  end

  def has_content?
    @has_content ||= false
  end

  def save_and_index(update = false)
    DRI::GenericFile.transaction do
      begin
        if generic_file.save && generic_file.update_index
          reason = update ? 'asset modified' : 'asset added'
          new_doi(object, reason) if object.status == "published"
          mint_or_update_doi(object) if object.status == 'published'
          @has_content = true
          true
        else
          raise ActiveRecord::Rollback
          false
        end
      rescue RSolr::Error::Http
        raise ActiveRecord::Rollback
        false
      end
    end
  end

  def characterize
    push_characterize_job
  end

  private

  def existing_moab_path(filename, filepath)
    preservation = Preservation::Preservator.new(object)
    preservation.existing_filepath(filepath)
  end

  def preserve_file(filedata, datastream, update=false)
    filename = "#{generic_file.alternate_id}_#{filedata[:filename]}"

    existing_moab_path = existing_moab_path(
                                    filedata[:filename],
                                    filedata[:file_upload].path
                                  )

    # attempting to replace existing file with duplicate
    if existing_moab_path && filedata[:filename] == generic_file.label
      raise DRI::Exceptions::MoabError, "File already preserved"
    end
    current_path = generic_file.path

    set_content(
      filedata[:file_upload],
      filedata[:filename],
      filedata[:mime_type],
      object.object_version,
      datastream,
      existing_moab_path
    )

    unless save_and_index(update)
      generic_file.delete_file if existing_moab_path.nil? && (generic_file.path != current_path)
      return false
    end

    changes = {}
    # Do the preservation actions
    if update && filedata[:filename] == generic_file.label
      # existing file content is being replaced
      changes[:modified] = { 'content' => [generic_file.path] }
    else
      changes[:added] = {'content' => [generic_file.path]}
      changes[:deleted] = if update
                            {'content' => ["#{generic_file.alternate_id}_#{generic_file.label}"] }
                          else
                            { 'content' => [] }
                          end
    end

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets(changes)
  end

  def push_characterize_job
    DRI.queue.push(CharacterizeJob.new(generic_file.alternate_id))
  end
end
