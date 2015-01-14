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

    if !pass_validation
      return false
    end

    gf = DRI::GenericFile.new(:pid => Sufia::IdService.mint)
    gf.batch = self
      
    # Apply depositor metadata, other permissions currently unused for generic files
    gf.apply_depositor_metadata(gf.batch.depositor)
      
    gf.save

    create_file(file, file_name, gf.id, dsid, "", mime_type.to_s)

    url = Rails.application.routes.url_helpers.url_for :controller=>"assets", :action=>"download", :object_id => gf.batch.id, :id=> gf.id
    gf.update_file_reference dsid, :url=>url, :mimeType=>mime_type.to_s

    begin
      gf.save!
      Sufia.queue.push(CharacterizeJob.new(gf.id))
    rescue Exception => e
      Rails.logger.error "Error saving file: #{e.message}"
      return false
    else
      return true
    end
  end

  private

  def local_storage_dir
    Rails.root.join(Settings.dri.files)
  end

  def create_file(file, file_name, object_id, datastream, checksum, mime_type)
    # Error: Couldn't find all LocalFiles with 'id': (all, {:conditions=>[\"fedora_id LIKE 
    # :f AND ds_id LIKE :d\", {:f=>\"dri:z603r3626\", :d=>\"content\"}]}) (found 0 results, but was looking for 2)
    # count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d", { :f => object_id, :d => datastream } ]).count
      
    # Changed to update use of deprecated method
    count = LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d", { :f => object_id, :d => datastream }).count

    dir = local_storage_dir.join(object_id).join(datastream+count.to_s)

    local_file = LocalFile.new
    local_file.add_file file, {:fedora_id => object_id, :file_name => file_name, :ds_id => datastream, :directory => dir.to_s, :version => count, :checksum => checksum, :mime_type => mime_type}

    begin
      local_file.save!
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Could not save the asset file #{@file.path} for #{object_id} to #{datastream}: #{e.message}"
    end
  end


end
