# Represents a file stored on the local filesystem.

require 'checksum'
require 'pathname'

class LocalFile < ActiveRecord::Base
  include Preservation::PreservationHelpers

  serialize :checksum

  def self.build_local_file(object:, generic_file:, data:, datastream:, opts: {})
    # prepare file
    file = LocalFile.new(fedora_id: generic_file.id, ds_id: datastream)
    options = {}
    options[:mime_type] = opts[:mime_type]
    options[:checksum] = opts[:checksum] if opts[:checksum].present?
    options[:batch_id] = object.id
    options[:object_version] = object.object_version || 1
    options[:file_name] = opts[:filename]

    # Add and save the file
    file.add_file(data, options)

    begin
      raise DRI::Exceptions::InternalError unless file.save!

      file
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Could not save the asset file #{file.path} for #{generic_file.id} to #{datastream}: #{e.message}"
      raise DRI::Exceptions::InternalError
    end
  end

  # TODO: reenable this as an admin function
  #before_destroy :delete_file

  # Write the file to the filesystem
  #
  def add_file(upload, opts = {})
    # Batch ID will be used in the MOAB directory name, check it exists
    batch_id = opts[:batch_id]
    if batch_id.blank?
      logger.error "Could not save the asset file for #{opts[:file_name]} because no batch_id was given."
      raise Exceptions::InternalError
    end

    self.version = opts[:object_version] || 1
    self.mime_type = opts[:mime_type]

    base_dir = opts[:directory].presence || File.join(content_path(batch_id, version))
    FileUtils.mkdir_p(base_dir)
    self.path = File.join(base_dir, opts[:file_name])

    upload_to_file(upload)

    self.checksum = if opts[:checksum]
                      { opts[:checksum] => Checksum.checksum(opts[:checksum], path) }
                    else
                      {}
                    end
  end

  def filename
    Pathname.new(path).basename.to_s
  end

  # Remove the file from the filesystem if it exists
  # This has been disabled for now so that only soft delete is possible
  # TODO reenable this as an admin function
  def delete_file
    return if path.nil? || !File.exist?(path)

    File.delete(path)

    pn = Pathname.new(path)
    FileUtils.remove_dir(pn.dirname, force: true)
  end

  private

    def local_storage_dir
      Rails.root.join(Settings.dri.files)
    end

    def upload_to_file(upload)
      if upload.respond_to?('path')
        FileUtils.cp(upload.path, path)
      else
        File.open(path, 'wb') { |f| f.write(upload.read) }
      end
      File.chmod(0644, path)
    end

end
