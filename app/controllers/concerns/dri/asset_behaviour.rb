module DRI::AssetBehaviour
  extend ActiveSupport::Concern

  def build_generic_file(object)
    @generic_file = DRI::GenericFile.new(id: DRI::Noid::Service.new.mint)
    @generic_file.batch = object
    @generic_file.apply_depositor_metadata(current_user)
    @generic_file.preservation_only = 'true' if params[:preservation] == 'true'
  end

  # asset controller
  def create_local_file(object, filedata, datastream, checksum, filename)
    # prepare file
    @file = LocalFile.new(fedora_id: @generic_file.id, ds_id: datastream)
    options = {}
    options[:mime_type] = @mime_type
    options[:checksum] = checksum unless checksum.nil?
    options[:batch_id] = object.id
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

  def preserve_file(filedata, datastream, params)
    checksum = params[:checksum]
    filename = params[:file_name].presence || filedata.original_filename
    filename = "#{@generic_file.id}_#{filename}"

    # Update object version
    version = @object.object_version || '1'
    object_version = (version.to_i + 1).to_s
    @object.object_version = object_version

    begin
      @object.save!
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Could not update object version number for #{@object.id} to version #{object_version}"
      raise Exceptions::InternalError
    end

    create_local_file(@object, filedata, datastream, checksum, filename)

    # Do the preservation actions
    addfiles = [filename]
    delfiles = []
    delfiles = ["#{@generic_file.id}_#{@generic_file.label}"] if params[:action] == 'update'
    
    preservation = Preservation::Preservator.new(@object)
    preservation.preserve_assets(addfiles, delfiles)
  end
end
