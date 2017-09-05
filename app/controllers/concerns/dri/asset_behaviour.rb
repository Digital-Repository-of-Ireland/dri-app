module DRI::AssetBehaviour
  extend ActiveSupport::Concern

  # asset controller
  def create_file(object, filedata, datastream, checksum, filename)
    # prepare file
    @file = LocalFile.new(fedora_id: @generic_file.noid, ds_id: datastream)
    options = {}
    options[:mime_type] = @mime_type
    options[:checksum] = checksum unless checksum.nil?
    options[:batch_id] = object.noid
    options[:object_version] = object.object_version || 1
    options[:file_name] = filename

    # Add and save the file
    @file.add_file(filedata, options)

    begin
      raise DRI::Exceptions::InternalError unless @file.save!
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Could not save the asset file #{@file.path} for #{@generic_file.id} to #{datastream}: #{e.message}"
      raise DRI::Exceptions::InternalError
    end

  end
end
