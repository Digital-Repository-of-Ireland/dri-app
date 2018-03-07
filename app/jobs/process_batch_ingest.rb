require 'ostruct'

class ProcessBatchIngest
  extend DRI::MetadataBehaviour
  extend DRI::AssetBehaviour

  @queue = :process_batch_ingest

  def self.perform(user_id, collection_id, ingest_json)
    ingest_batch = JSON.parse(ingest_json)

    user = UserGroup::User.find(user_id)
    collection = DRI::Batch.find(collection_id, cast: true)

    download_path = File.join(Settings.downloads.directory, collection_id)
    FileUtils.mkdir_p(download_path)

    # retrieve information about metadata file to be ingested
    metadata_info = ingest_batch['metadata']

    object = if metadata_info['object_id'].present?
               # metadata ingest was successful so only ingest missing assets
               DRI::Batch.find(metadata_info['object_id'], cast: true)
             else
               metadata = retrieve_files(download_path, [metadata_info])[0]
               ingest_metadata(collection, user, metadata)
             end

    assets = retrieve_files(download_path, ingest_batch['files'])
    ingest_assets(user, object, assets)
  end

  def self.ingest_assets(user, object, assets)
    assets.each do |asset|
      build_generic_file(object, user)

      original_file_name = File.basename(asset[:path])
      file_name = "#{@generic_file.id}_#{original_file_name}"

      version = ingest_file(asset[:path], object, 'content', file_name)
      saved = if version < 1
                false
              else
                url = Rails.application.routes.url_helpers.url_for(
                        controller: 'assets',
                        action: 'download',
                        object_id: object.id,
                        id: @generic_file.id,
                        version: version
                      )
                DRI::Asset::Actor.new(@generic_file, user).create_external_content(
                  url,
                  'content',
                  file_name
                )
                true
              end
    
      update = if saved
                 { status_code: 'COMPLETED',
                   file_location: Rails.application.routes.url_helpers.object_file_path(object, @generic_file) }
               else
                 { status_code: 'FAILED' }
               end

      update_master_file(asset[:master_file_id], update)
    end
  end

  def self.ingest_metadata(collection, user, metadata) 
    xml = load_xml(file_data(metadata[:path]))
    object = create_object(collection, user, xml)

    update = if object.valid? && object.save
               create_reader_group if object.collection?

               DRI::Object::Actor.new(object, user).version_and_record_committer

               preservation = Preservation::Preservator.new(object)
               preservation.preserve(true, true, ['descMetadata','properties'])

               { status_code: 'COMPLETED',
                 file_location: Rails.application.routes.url_helpers.my_collections_path(object) }
             else
               { status_code: 'FAILED', file_location: "error:#{object.errors.full_messages.inspect}" }
              end

    update_master_file(metadata[:master_file_id], update)
    FileUtils.rm_f(metadata[:path])

    object
  end

  def self.ingest_file(file_path, object, datastream, filename)
    filedata = OpenStruct.new
    filedata.path = file_path
    
    current_version = object.object_version || '1'
    object_version = (current_version.to_i+1).to_s

    object.object_version = object_version
    
    # Update object version
    begin
      object.save
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Could not update object version number for #{object.id} to version #{object_version}"
      return -1
    end

    begin
      create_local_file(object, filedata, datastream, nil, filename)
    rescue StandardError => e
      Rails.logger.error "Could not save the asset file #{filedata.path} for #{object.id} to #{datastream}: #{e.message}"
      return -1
    end

    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets([filename],[])

    FileUtils.rm_f(file_path)
    
    object.object_version.to_i
  end

  def self.create_object(collection, user, xml)
    standard = metadata_standard_from_xml(xml)

    object = DRI::Batch.with_standard standard
    object.governing_collection = collection
    object.depositor = user.to_s
    object.status = 'draft'
    object.object_version = '1'

    set_metadata_datastream(object, xml)
    checksum_metadata(object)

    object
  end

  def self.create_reader_group(object)
    group = UserGroup::Group.new(
      name: object.id.to_s,
      description: "Default Reader group for collection #{object.id}"
    )
    group.reader_group = true
    group.save
  end

  def self.download_url(generic_file)
    Rails.application.routes.url_helpers.url_for controller: 'assets',
             action: 'download', object_id: generic_file.batch.id, id: generic_file.id
  end

  def self.file_data(path)
    file_upload = OpenStruct.new
    file_upload.tempfile = File.new(path)
    file_upload.original_filename = File.basename(path)

    file_upload
  end

  def self.retrieve_files(download_path, files)
    retriever = BrowseEverything::Retriever.new

    downloaded_files = []

    files.each do |file|
      download_location = File.join(download_path, file['download_spec']['file_name'])
      downloaded = 0
      File.open download_location, 'wb' do |dest|
        # Retrieve the file, yielding each chunk to a block
        retriever.retrieve(file['download_spec']) do |chunk, retrieved, total|
          dest.write chunk
          downloaded = retrieved
        end
      end

      download = { label: file['label'], path: download_location, master_file_id: file['id'] }
      downloaded_files << download
    end

    downloaded_files
  end

  def self.update_master_file(id, update)
    master_file = DriBatchIngest::MasterFile.find(id)
    master_file.status_code = update[:status_code]
    master_file.file_location = update[:file_location]
    master_file.save
  end
end
