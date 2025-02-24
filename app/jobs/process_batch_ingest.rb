require 'ostruct'
require 'validators'

class ProcessBatchIngest
  @queue = :process_batch_ingest

  def self.perform(user_id, collection_id, ingest_json)
    ingest_batch = JSON.parse(ingest_json)

    user = UserGroup::User.find(user_id)

    download_path = File.join(Settings.downloads.directory, collection_id)
    FileUtils.mkdir_p(download_path) unless File.exist?(download_path)

    # retrieve information about metadata file to be ingested
    metadata_info = ingest_batch['metadata']

    rc, object = if metadata_info['object_id'].present?
                   # metadata ingest was successful so only ingest missing assets
                   [0, DRI::DigitalObject.find_by_alternate_id(metadata_info['object_id'])]
                 else
                   metadata = retrieve_files(download_path, [metadata_info])[0]
                   ingest_metadata(collection_id, user, metadata)
                 end

    if rc == 0 && object
      assets = retrieve_files(download_path, ingest_batch['files'])
      unless assets.empty?
        object.increment_version

        # potentially loses connection during file downloads
        ActiveRecord::Base.connection_handler.clear_active_connections!
        object.save

        ingest_assets(user, object, assets)
      end
      ActiveRecord::Base.connection_handler.clear_active_connections!
      record_committer(object, user)
    end
  end

  def self.ingest_assets(user, object, assets)
    filenames = []

    assets.each do |asset|
      # the asset file was not found
      if asset[:path].start_with?('error:')
        update_master_file(asset[:master_file_id], { status_code: 'FAILED', file_location: asset[:path] })
        next
      end

      preservation = asset[:label] == 'preservation'
      build_generic_file(object: object, user: user, preservation: preservation)

      original_file_name = File.basename(asset[:path])

      moab_filename = ingest_file(user, asset[:path], object, 'content', original_file_name)
      saved = if moab_filename.nil?
                false
              else
                filenames << moab_filename
                true
              end

      update = if saved
                 { status_code: 'COMPLETED',
                   file_location: Rails.application.routes.url_helpers.object_file_path(object.alternate_id, @generic_file.alternate_id) }
               else
                 { status_code: 'FAILED' }
               end

      update_master_file(asset[:master_file_id], update)
    end

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets({ added: { 'content' => filenames }})

    assets.reject { |asset| asset[:path].start_with?('error:') }.each { |asset| FileUtils.rm_f(asset[:path]) }
  end

  def self.ingest_metadata(collection_id, user, metadata)
    download_path = metadata[:path]
    # the metadata file could not be retrieved
    if download_path.start_with?('error:')
       update_master_file(metadata[:master_file_id], { status_code: 'FAILED', file_location: download_path })
       return -1, nil
    end

    xml_ds = XmlDatastream.new

    begin
      xml_ds.load_xml(file_data(download_path))
    rescue DRI::Exceptions::InvalidXML, DRI::Exceptions::ValidationErrors => e
      update = { status_code: 'FAILED', file_location: "error: invalid metadata: #{e.message}" }
      update_master_file(metadata[:master_file_id], update)
      FileUtils.rm_f(metadata[:path])

      return -1, nil
    end

    object = create_object(collection_id, user, xml_ds)

    if !object.valid?
      update = { status_code: 'FAILED', file_location: "error: invalid metadata: #{object.errors.full_messages.join(', ')}" }
      update_master_file(metadata[:master_file_id], update)
      FileUtils.rm_f(metadata[:path])

      return -1, object
    end

    begin
      object.index_needs_update = false
      rc, update = if save_and_index(object)
                    create_reader_group(object) if object.collection?

                    preservation = Preservation::Preservator.new(object)
                    preservation.preserve(['descMetadata'])

                    [
                      0,
                      { status_code: 'COMPLETED',
                        file_location: Rails.application.routes.url_helpers.my_collections_path(object.alternate_id) }
                    ]
                  else
                    raise DRI::Exceptions::InternalError
                  end
    rescue ActiveRecord::RecordNotSaved, RSolr::Error::Http, DRI::Exceptions::InternalError => e
      update =  { status_code: 'FAILED', file_location: "error: unable to persist object to repository. #{e.message}" }
      rc = -1
    end
    update_master_file(metadata[:master_file_id], update)
    FileUtils.rm_f(metadata[:path])

    return rc, object
  end

  def self.save_and_index(object)
    object.index_needs_update = false

    DRI::DigitalObject.transaction do
      begin
        raise ActiveRecord::Rollback unless object.save && object.update_index
      rescue RSolr::Error::Http => e
        raise ActiveRecord::Rollback
      end
    end
    object.persisted?
  end

  def self.ingest_file(user, file_path, object, datastream, filename)
    mime_type = Validators.file_type(file_path)
    file_content = GenericFileContent.new(
                       user: user,
                       object: object,
                       generic_file: @generic_file
                   )

    existing_content = DRI::GenericFile.where(label: filename)
    if !existing_content.empty?
      if Checksum.md5(existing_content[0].path) == Checksum.md5(file_path)
        preservation = Preservation::Preservator.new(object)
        moab_path = existing_content[0].path.split(preservation.aip_dir(object.alternate_id))[1]
      end
    end

    file_content.set_content(File.new(file_path), filename, mime_type, object.object_version, datastream, moab_path)
    return nil unless file_content.save_and_index
    file_content.characterize if file_content.has_content?

    @generic_file.path
  rescue StandardError => e
    Rails.logger.error "Could not save the asset file #{file_path} for #{object.alternate_id} to #{datastream}: #{e.message}"
    nil
  end

  def self.build_generic_file(object:, user:, preservation: false)
    @generic_file = DRI::GenericFile.new(alternate_id: DRI::Noid::Service.new.mint)
    @generic_file.digital_object = object
    @generic_file.apply_depositor_metadata(user)
    @generic_file.preservation_only = 'true' if preservation
  end

  def self.create_object(collection_id, user, xml_ds)
    standard = xml_ds.metadata_standard

    object = DRI::DigitalObject.with_standard standard
    object.governing_collection = DRI::DigitalObject.find_by_alternate_id(collection_id)
    object.depositor = user.to_s
    object.status = 'draft'
    object.object_version = 1
    object.visibility = object.governing_collection.visibility
    
    object.update_metadata(xml_ds.xml)
    checksum_metadata(object)

    object
  end

  def self.create_reader_group(object)
    group = UserGroup::Group.new(
      name: object.alternate_id,
      description: "Default Reader group for collection #{object.alternate_id}"
    )
    group.reader_group = true
    group.save
  end

  def self.file_data(path)
    file_upload = OpenStruct.new
    file_upload.tempfile = File.new(path)
    file_upload.original_filename = File.basename(path)

    file_upload
  end

  def self.retrieve_files(download_path, files)
    downloaded_files = []

    files.each do |file|
      # using the path of the file in cloud storage to handle case when
      # preservation asset and display asset have same filename and extension
      cloud_path = File.dirname(file['download_spec']['url']).split('/').last
      FileUtils.mkdir_p(File.join(download_path, cloud_path))
      download_location = File.join(download_path, cloud_path, file['download_spec']['file_name'])
      download_location = download(download_location, file['download_spec'])

      download = { label: file['label'], path: download_location, master_file_id: file['id'] }
      downloaded_files << download
    end

    downloaded_files
  end

  def self.download(download_location, download_spec)
    downloaded = 0
    retriever = BrowseEverything::Retriever.new
    File.open download_location, 'wb' do |dest|
      # Retrieve the file, yielding each chunk to a block
      retriever.retrieve(download_spec) do |chunk, retrieved, total|
        dest.write chunk
        downloaded = retrieved
      end
    end

    download_location
  rescue Errno::ENOENT => e
    "error: #{e.message}"
  end

  def self.update_master_file(id, update)
    master_file = DRIBatchIngest::MasterFile.find(id)
    master_file.status_code = update[:status_code]
    master_file.file_location = update[:file_location]
    master_file.save
  end

  def self.record_committer(object, user)
    VersionCommitter.create(version_id: version_id(object), obj_id: object.alternate_id, committer_login: user.to_s)
  end

  def self.version_id(object)
    'v%04d' % object.object_version
  end

  def self.checksum_metadata(object)
    if object.attached_files.key?(:descMetadata)
      xml = object.attached_files[:descMetadata].content
      object.metadata_checksum = Checksum.md5_string(xml)
    end
  end
end
