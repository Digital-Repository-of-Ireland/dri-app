require 'ostruct'

class ProcessBatchIngest
  @queue = :process_batch_ingest
  
  def self.auth_url(user, url)
    "#{url}?user_email=#{user.email}&user_token=#{user.authentication_token}"
  end

  def self.perform(user_id, collection_id, ingest_json)
    ingest_batch = JSON.parse(ingest_json)
    
    user = UserGroup::User.find(user_id)
    collection = DRI::Batch.find(collection_id, cast: true)

    download_path = File.join(Settings.downloads.directory, collection_id)
    FileUtils.mkdir_p(download_path)

    ingest_files = ingest_batch['files']
    metadata, assets = retrieve_files(download_path, ingest_files)

    object = ingest_metadata(collection, user, metadata)
    ingest_assets(user, object, assets)
  end

  def self.ingest_assets(user, object, assets)
    assets.each do | asset|
      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = object
      generic_file.apply_depositor_metadata(user)
      generic_file.preservation_only = 'true' if asset[:label] == 'preservation'

      filename = File.basename(asset[:path]) 
      if create_file(asset[:path], generic_file, 'content', filename)
        saved = DRI::Asset::Actor.new(generic_file, user).create_external_content(
          URI.escape(download_url(generic_file)), 
          'content', filename)
      else
        saved = false
      end
      
      if saved
        message = { status_code: 'COMPLETED', 
          file_location: Rails.application.routes.url_helpers.object_file_path(object, generic_file) }
      else
        message = { status_code: 'FAILED' }
      end

      send_message(auth_url(user, asset[:callback_url]), message)
    end
  end

  def self.ingest_metadata(collection, user, metadata)
    xml = MetadataHelpers.load_xml(file_data(metadata[:path]))
    object = create_object(collection, user, xml)
    
    if object.valid? && object.save
      create_reader_group if object.collection?
      
      DRI::Object::Actor.new(object, user).version_and_record_committer
      status = 'COMPLETED'
      message = { status_code: 'COMPLETED', 
        file_location: Rails.application.routes.url_helpers.catalog_path(object) }
    else
      message = { status_code: 'FAILED' }
    end

    send_message(auth_url(user, metadata[:callback_url]), message)
    object
  end

  def self.create_file(file_path, generic_file, datastream, filename = nil)
    filedata = OpenStruct.new
    filedata.path = file_path

    file = LocalFile.new(fedora_id: generic_file.id, ds_id: datastream)
    options = {}
    options[:mime_type] = Validators.file_type?(filedata)
    options[:file_name] = filename unless filename.nil?

    file.add_file filedata, options

    begin
      file.save!
      saved = true
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Could not save the asset file #{@file.path} for #{generic_file.id} to #{datastream}: #{e.message}"
      saved = false
    end

    saved
  end

  def self.create_object(collection, user, xml)
    standard = MetadataHelpers.get_metadata_standard_from_xml xml

    object = DRI::Batch.with_standard standard
    object.governing_collection = collection
    object.depositor = user.to_s
    object.status = 'draft'

    MetadataHelpers.set_metadata_datastream(object, xml)
    MetadataHelpers.checksum_metadata(object)

    object
  end

  def self.create_reader_group(object)
    group = UserGroup::Group.new(name: "#{object.id}", 
      description: "Default Reader group for collection #{object.id}")
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

    metadata = {}
    assets = []

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

      if file['label'] == 'metadata'
        metadata = { path: download_location, callback_url: file['callback_url'] }
      else
        asset = { label: file['label'], path: download_location, callback_url: file['callback_url'] }
        assets << asset
      end
    end
    
    return metadata, assets
  end

  def self.send_message(url, message)
    RestClient.put url, { 'master_file' => message }, content_type: :json, accept: :json
  rescue RestClient::Exception => e
    Rails.logger.error "Error sending callback: #{e}"
  end
end
