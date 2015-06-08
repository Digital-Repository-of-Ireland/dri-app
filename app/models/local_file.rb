# Represents a file stored on the local filesystem.

require 'checksum'
require 'pathname'

class LocalFile < ActiveRecord::Base
  serialize :checksum

  before_destroy :delete_file

  # Write the file to the filesystem
  #
  def add_file(upload,opts={})
    file_name = ""

    if opts.key?(:file_name)
      file_name = opts[:file_name]
    else
      file_name = upload.original_filename
    end
    
    self.version = version_number
    self.mime_type = opts[:mime_type]

    base_dir = opts[:directory].present? ? opts[:directory] : File.join(local_storage_dir, content_path)
    self.path = File.join(base_dir, file_name)

    FileUtils.mkdir_p(base_dir)
    if upload.respond_to?('path')
      FileUtils.cp(upload.path, self.path)
    else
      File.open(self.path, "wb") { |f| f.write(upload.read) }
    end

    File.chmod(0644, self.path)

    unless opts[:checksum].blank?
      self.checksum = { opts[:checksum] => Checksum.checksum(opts[:checksum], self.path) }
    else
      self.checksum = {}
    end
  end

  # Remove the file from the filesystem if it exists
  #
  def delete_file
    return if self.path.nil?

    if File.exist?(self.path)
      File.delete(self.path)

      pn = Pathname.new(self.path)
      FileUtils.remove_dir(pn.dirname, :force => true)
    end
  end

  private

    def local_storage_dir
      Rails.root.join(Settings.dri.files)
    end

    def content_path
      File.join(build_hash_dir, self.ds_id+self.version.to_s)
    end

    def build_hash_dir
      dir = ""
      index = 0

      4.times {
        dir = File.join(dir, self.fedora_id[index..index+1])
        index += 2
      }

      dir = File.join(dir, self.fedora_id)
    end

    def version_number
      LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d", { :f => self.fedora_id, :d => self.ds_id }).count
    end

end
