class GenericFileContent
  include ActiveModel::Model

  attr_accessor :object, :generic_file, :user

  def add_content(file_upload, filename, mime_type, download_url, path='content')
    set_content(false, file_upload, filename, mime_type, download_url, path)
  end

  def update_content(file_upload, filename, mime_type, download_url, path='content')
    set_content(true, file_upload, filename, mime_type, download_url, path)
  end

  def checksum
    @file.checksum
  end

  def external_content(url, filename, path='content')
    generic_file.add_file('', path: path, original_name: filename, mime_type: external_mime_type(url))
    generic_file.label = filename
    generic_file.title = [filename]

    save_characterize_and_record_committer
  end

  def local_file(version = nil, datastream = 'content')
    return @local_file if @local_file

    search_params = { f: generic_file.id, d: datastream }
    search_params[:v] = version unless version.nil?

    query = 'fedora_id LIKE :f AND ds_id LIKE :d'
    query << ' AND version = :v' if search_params[:v].present?

    @local_file = LocalFile.where(query, search_params).order(version: :desc).first
  rescue ActiveRecord::RecordNotFound
    raise DRI::Exceptions::InternalError, "Unable to find requested file"
  rescue ActiveRecord::ActiveRecordError
    raise DRI::Exceptions::InternalError, "Error finding file"
  end

  private

  def set_content(update, file_upload, filename, mime_type, download_url, path='content')
    preserved_file = preserve_file(file_upload, filename, mime_type, path, update)
    url = "#{URI.escape(download_url)}?version=#{preserved_file.version}"

    external_content(url, preserved_file.filename)
  end

  def preserve_file(filedata, filename, mime_type, datastream, update=false)
    filename = "#{generic_file.id}_#{filename}"

    # Update object version
    object.object_version ||= '1'
    object.increment_version

    begin
      object.save!
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Could not update object version number for #{object.id} to version #{object.object_version}"
      raise Exceptions::InternalError
    end

    @file = LocalFile.build_local_file(
      object: object,
      generic_file: generic_file,
      data: filedata,
      datastream: datastream,
      opts: { filename: filename, mime_type: mime_type, checksum: 'md5' }
    )

    # Do the preservation actions
    addfiles = [filename]
    delfiles = []
    delfiles = ["#{generic_file.id}_#{generic_file.label}"] if update

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets(addfiles, delfiles)

    @file
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

    generic_file.record_version_committer(user)
    true
  end

  def push_characterize_job
    DRI.queue.push(CharacterizeJob.new(generic_file.id))
  end

  def external_mime_type(url)
    "message/external-body; access-type=URL; URL=\"#{url}\""
  end

end
