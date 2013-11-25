require "hydra/derivatives/extract_metadata"
require "sufia/models/file_content"
FileContentDatastream.class_eval do
  # Quick fix to get the content from storage and avoid using the REST API
  def to_tempfile(&block)
    return unless has_content?

    source = nil

    if ['E','R'].include? controlGroup
      @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                                { :f => pid, :d => "content" } ],
                                            :order => "version DESC",
                                            :limit => 1)
      source = File.open(@local_file_info[0].path, 'r')
    

    type = @local_file_info[0].mime_type
    extension = "."+@local_file_info[0].path.split(".").last

    # hmm, changing mp2 to mp3 forces FITS to measure audio channels, bitrate and duration
    if (extension == '.mp2')
      extension = '.mp3'
    end

    logger.warn "Unable to find a registered mime type for #{mimeType.inspect} on #{pid}" unless type

    Tempfile.open(["#{pid}-#{dsVersionID}", extension]) do |f|
        f.binmode
        if source.respond_to? :read
          f.write(source.read)
        else
          f.write(source)
        end
        source.rewind if source.respond_to? :rewind
        f.rewind
        yield(f)
    end
  end
  end

end