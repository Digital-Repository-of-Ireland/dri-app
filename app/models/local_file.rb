# Represents a file stored on the local filesystem.

require 'checksum'
require 'pathname'

class LocalFile < ActiveRecord::Base
  serialize :checksum

  before_destroy :delete_file

  # Write the file to the filesystem
  #
  def add_file(upload, opts = {})
    file_name = opts[:file_name].presence || upload.original_filename

    self.version = version_number
    self.mime_type = opts[:mime_type]

    base_dir = opts[:directory].presence || File.join(local_storage_dir, content_path)
    FileUtils.mkdir_p(base_dir) 
    self.path = File.join(base_dir, file_name)
   
    upload_to_file(base_dir, upload)

    if opts[:checksum]
      self.checksum = { opts[:checksum] => Checksum.checksum(opts[:checksum], path) }
    else
      self.checksum = {}
    end
  end

  # Remove the file from the filesystem if it exists
  #
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

    def content_path
      File.join(build_hash_dir, ds_id+version.to_s)
    end

    def build_hash_dir
      dir = ''
      index = 0

      4.times {
        dir = File.join(dir, fedora_id[index..index+1])
        index += 2
      }

      File.join(dir, fedora_id)
    end

    def upload_to_file(base_dir, upload)
      if upload.respond_to?('path')
        FileUtils.cp(upload.path, path)
      else
        File.open(path, 'wb') { |f| f.write(upload.read) }
      end

      File.chmod(0644, path)
    end

    def version_number
      LocalFile.where('fedora_id LIKE :f AND ds_id LIKE :d', { f: fedora_id, d: self.ds_id }).count
    end

end
