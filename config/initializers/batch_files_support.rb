require "dri/model_support/files"
require 'validators'


DRI::ModelSupport::Files.module_eval do

	def add_file file, dsid="content",file_name
	  mime_type = Validators.file_type?(file.path)
      pass_validation = false

	  begin
        pass_validation = Validators.validate_file(file.path, mime_type)
      rescue Exception => e
        logger.error "Error validating file: #{e.message}"
        return false
      end

      if !pass_validation
      	return false
      end

      gf = GenericFile.new(:pid => Sufia::IdService.mint)
      gf.batch = self
      gf.save

      create_file(file, file_name, gf.id, dsid, "")

      url = "http://repository.dri.ie/v1/objects/#{gf.id}/file"
      gf.update_file_reference dsid, :url=>url, :mimeType=>mime_type.to_s

      begin
          gf.save!
      rescue Exception => e
          logger.error "Error saving file: #{e.message}"
        return false
      else
        return true
      end
    end

    private

    def local_storage_dir
      Rails.root.join(Settings.dri.files)
    end

    def create_file(file, file_name, object_id, datastream, checksum)
      count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d", { :f => object_id, :d => datastream } ]).count

      dir = local_storage_dir.join(object_id).join(datastream+count.to_s)

      local_file = LocalFile.new
      local_file.add_file file, {:fedora_id => object_id, :file_name => file_name, :ds_id => datastream, :directory => dir.to_s, :version => count, :checksum => checksum}

      begin
        local_file.save!
      rescue ActiveRecordError => e
        logger.error "Could not save the asset file #{@file.path} for #{object_id} to #{datastream}: #{e.message}"
      end
    end


end