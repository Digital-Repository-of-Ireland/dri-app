# Represents a file stored on the local filesystem.

require 'checksum'
require 'pathname'
require 'preservation/preservation_helpers'

class LocalFile < ActiveRecord::Base
  include PreservationHelpers

  serialize :checksum

  # TODO: reenable this as an admin function
  #before_destroy :delete_file

  # Write the file to the filesystem
  #
  def add_file(upload, opts = {})
    # Batch ID will be used in the MOAB directory name, check it exists
    batch_id = opts[:batch_id]
    if batch_id.nil? or batch_id.blank?
      logger.error "Could not save the asset file for #{opts[:file_name]} because no batch_id was given."
      raise Exceptions::InternalError
    end

    self.version = opts[:object_version] || 1
    self.mime_type = opts[:mime_type]

    base_dir = opts[:directory].presence || File.join(content_path(batch_id, version))
    FileUtils.mkdir_p(base_dir)
    self.path = File.join(base_dir, opts[:file_name])

    upload_to_file(base_dir, upload)

    self.checksum = if opts[:checksum]
                      { opts[:checksum] => Checksum.checksum(opts[:checksum], path) }
                    else
                      {}
                    end
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

    def upload_to_file(base_dir, upload)
      if upload.respond_to?('path')
        FileUtils.cp(upload.path, path)
      else
        File.open(path, 'wb') { |f| f.write(upload.read) }
      end
      File.chmod(0644, path)
    end

end
