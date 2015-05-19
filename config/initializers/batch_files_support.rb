require "dri/model_support/files"
require 'validators'


DRI::ModelSupport::Files.module_eval do

  def add_file file, dsid="content", file_name
    mime_type = Validators.file_type?(file.path)
    pass_validation = false

    begin
      pass_validation = Validators.validate_file(file.path, mime_type)
    rescue Exception => e
      Rails.logger.error "Error validating file: #{e.message}"
      return false
    end

    unless pass_validation
      return false
    end

    gf = DRI::GenericFile.new(:id => Sufia::IdService.mint)
    gf.batch = self
      
    # Apply depositor metadata, other permissions currently unused for generic files
    ingest_user = UserGroup::User.find_by_email(gf.batch.depositor)    
    gf.apply_depositor_metadata(gf.batch.depositor)

    @actor = DRI::Asset::Actor.new(gf, ingest_user)
    url = "#{ActiveFedora.fedora_config.credentials[:url]}/federated/#{build_path(gf.id,dsid)}/#{file_name}"

    create_file(file, file_name, gf.id, dsid, "", mime_type.to_s)

    if @actor.create_external_content(url, dsid, file_name)
      return true
    else
      Rails.logger.error "Error saving file: #{e.message}"
      return false
    end
  end

  private

  def local_storage_dir
    Rails.root.join(Settings.dri.files)
  end

  def build_path(object_id, datastream)
    "#{object_id}/#{datastream+@actor.version_number(datastream).to_s}"
  end

  def create_file(file, file_name, object_id, datastream, checksum, mime_type)
    dir = local_storage_dir.join(build_path(object_id, datastream))

    local_file = LocalFile.new
    local_file.add_file file, {:fedora_id => object_id, :file_name => file_name, :ds_id => datastream, :directory => dir.to_s, :version => @actor.version_number(datastream), :checksum => checksum, :mime_type => mime_type}

    begin
      local_file.save!
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Could not save the asset file #{file.path} for #{object_id} to #{datastream}: #{e.message}"
    end
  end


end
