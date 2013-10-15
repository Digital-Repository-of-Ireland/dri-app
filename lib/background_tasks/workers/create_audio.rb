class CreateAudio

  require 'open3'
  require 'tempfile'
  require 'storage/s3_interface'

  def self.perform(object_id)
    Rails.logger.info "Creating #{@type} version of #{object_id} asset"

    datastream = "masterContent"
    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                             { :f => object_id, :d => datastream } ],
                                      :order => "version DESC",
                                      :limit => 1)
    masterfile = @local_file_info.first.path
    outputfile = Tempfile.new(["output_file",".#{@type}"])
    output_path = outputfile.path

    begin
      begin
        transcode(masterfile, output_options, output_path)

        filename = "#{object_id}_#{@type}_web_quality.#{@type}"
        Storage::S3Interface.store_surrogate(object_id, output_path, filename)
      rescue Exceptions::BadCommand => e
        Rails.logger.error "Failed to transcode file #{e.message}"
        # requeue?
      end
    ensure
      File.unlink(outputfile)
    end
  end


  def self.executable
    Settings.plugins.ffmpeg_path
  end

  # Transcode the file
  def self.transcode(input_file, options, output_file)
    command = "#{executable} -y -i #{input_file} #{options} #{output_file}"
    stdin, stdout, stderr, wait_thr = Open3::popen3(command)
    stdin.close
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close
    raise Exceptions::BadCommand.new "Unable to execute command \"#{command}\"\n#{err}" unless wait_thr.value.success?
  end


end
