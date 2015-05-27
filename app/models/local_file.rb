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

    
    self.path = File.join(opts[:directory], file_name)
    self.fedora_id = opts[:fedora_id]
    self.ds_id = opts[:ds_id]
    self.version = opts[:version]
    self.mime_type = opts[:mime_type] 

    FileUtils.mkdir_p(opts[:directory])
    if upload.respond_to?('path')
      FileUtils.mv(upload.path, self.path)
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
    if self.path.nil?
      return
    end

    if File.exist?(self.path)
      File.delete(self.path)

      pn = Pathname.new(self.path)
      FileUtils.remove_dir(pn.dirname, :force => true)
    end
  end

end
