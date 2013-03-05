# Represents a file stored on the local filesystem.

require 'digest/md5'

class LocalFile < ActiveRecord::Base
  serialize :checksum

  # Write the file to the filesystem
  #
  def add_file(upload,opts={}) 
    filename = upload.original_filename
    self.path = File.join(opts[:directory], filename)
    self.fedora_id = opts[:fedora_id]
    self.ds_id = opts[:ds_id]
    self.version = opts[:version]
    self.mime_type = MIME::Types.type_for(filename).first.content_type 

    FileUtils.mkdir_p(opts[:directory])
    File.open(self.path, "wb") { |f| f.write(upload.read) }

    self.checksum = { :md5 => md5_checksum(self.path) }
  end

  # Remove the file from the filesystem if it exists
  #
  def delete_file
    if self.path = nil
      return
    end

    if File.exist?(self.path)
      File.delete(self.path)
    end
  end

  def md5_checksum(file)
    Digest::MD5.file(file).hexdigest
  end

end
