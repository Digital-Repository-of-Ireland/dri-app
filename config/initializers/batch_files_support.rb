require 'dri/model_support/files'
require 'validators'

DRI::ModelSupport::Files.module_eval do

  def add_file(file, dsid='content', file_name)
    mime_type = Validators.file_type(file.path)
    pass_validation = false

    begin
      pass_validation = Validators.validate_file(file.path, mime_type)
    rescue Exception => e
      Rails.logger.error "Error validating file: #{e.message}"
      return false
    end

    return false unless pass_validation

    gf = DRI::GenericFile.new(id: DRI::Noid::Service.new.mint)
    gf.batch = self
    file_name = "#{gf.id}_#{original_file_name}"
      
    # Apply depositor metadata, other permissions currently unused for generic files
    ingest_user = UserGroup::User.find_by_email(gf.batch.depositor)    
    gf.apply_depositor_metadata(gf.batch.depositor)

    @actor = DRI::Asset::Actor.new(gf, ingest_user)

    version = create_file(file, file_name, gf.id, dsid, '', mime_type.to_s)
 
    url = Rails.application.routes.url_helpers.url_for(
      controller: 'assets',
      action: 'download',
      object_id: gf.batch.id,
      id: gf.id,
      version: version
    )

    if @actor.create_external_content(URI.escape(url), dsid, file_name)
      return true
    else
      Rails.logger.error "Error saving file: #{e.message}"
      return false
    end
  end

  private

  def create_file(file, file_name, gf, datastream, checksum, mime_type)
    object_version = (gf.batch.object_version.to_i+1).to_s
    object_id = gf.id
    batch_id = gf.batch.id

    local_file = LocalFile.new(fedora_id: object_id, ds_id: datastream)
    local_file.add_file file, { batch_id: batch_id, file_name: file_name, checksum: checksum, mime_type: mime_type, object_version: object_version}

    # Do the preservation actions
    gf.batch.object_version = object_version
    preservation = Preservation::Preservator.new(gf.batch)
    preservation.preserve_assets([file_name],[])

    # Update object version
    begin
      gf.batch.save
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Could not update object version number for #{generic_file.batch.id} to version #{options[:object_version]}"
      raise Exceptions::InternalError
    end

    begin
      local_file.save!
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Could not save the asset file #{file.path} for #{object_id} to #{datastream}: #{e.message}"
    end

    local_file.version
  end

end
