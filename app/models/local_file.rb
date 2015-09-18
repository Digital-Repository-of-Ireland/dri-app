# Represents a file stored on the local filesystem.

require 'checksum'
require 'pathname'

class LocalFile < ActiveRecord::Base
  serialize :checksum

  before_destroy :delete_file

  # Write the file to the filesystem
  #
  def add_file(upload,opts={})

    file_name = opts[:file_name].presence || upload.original_filename
    file_name = "#{self.fedora_id}_#{file_name}"

    # Batch ID will be used in the MOAB directory name, check it exists
    batch_id = opts[:batch_id]
    if batch_id.nil? or batch_id.blank?
      logger.error "Could not save the asset file for #{file_name} because no batch_id was given."
      raise Exceptions::InternalError
    end

    self.version = version_number
    self.mime_type = opts[:mime_type]

    base_dir = opts[:directory].presence || File.join(local_storage_dir, content_path(batch_id))
    self.path = File.join(base_dir, file_name)

    FileUtils.mkdir_p(base_dir)
    if upload.respond_to?('path')
      FileUtils.cp(upload.path, self.path)
    else
      File.open(self.path, "wb") { |f| f.write(upload.read) }
    end

    File.chmod(0644, self.path)

    if opts[:checksum]
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


    # Return the hash dir and version dir part of the file path
    # if batch object id is passed in then it will use that
    # otherwise will use generic_file id
    # input (optional): batch string (fedora object id)
    # output: partial path string e.g. "1c/18/df/87/1c18df87m/v0001"
    def content_path(batch=nil)
      pid = batch ? batch : self.fedora_id
      File.join(build_hash_dir(batch), version_path)
    end


    # Return formatted version number for the file path
    # versions start at 0, but MOAB expects v0001 as first version
    # output: incremented & formatted version number String of format vxxxx
    def version_path
      'v%04d' % self.version+1.to_s
    end


    # Return the hash part of the file path
    # input (optional): batch String (fedora object id) 
    # output: partial path String e.g. "1c/18/df/87/1c18df87m"
    def build_hash_dir(batch)
      dir = ""
      index = 0
      pid = batch ? batch : self.fedora_id
      

      4.times {
        dir = File.join(dir, pid[index..index+1])
        index += 2
      }

      File.join(dir, pid)
    end


    # Return the version number
    # output: count Fixnum
    def version_number
      LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d", { :f => self.fedora_id, :d => self.ds_id }).count
    end

end
