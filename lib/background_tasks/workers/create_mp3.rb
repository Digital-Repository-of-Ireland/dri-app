class CreateMp3
  @queue = "create_mp3_queue"

  require 'open3'
  require 'storage/s3_interface'

  def self.perform(object_id)
    Rails.logger.info "Creating mp3 version of #{object_id} asset"

    datastream = "masterContent"
    @object = ActiveFedora::Base.find(object_id,{:cast => true})
    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                             { :f => @object.id, :d => datastream } ],
                                      :order => "version DESC",
                                      :limit => 1)
    masterfile = @local_file_info.first.path

    tmp_dir = File.join(Dir::tmpdir, "dri_mp3_#{Time.now.to_i}_#{rand(100)}")
    Dir.mkdir(tmp_dir)
    workingfile = File.join(tmp_dir, File.basename(masterfile))
    FileUtils.cp(masterfile,workingfile)
    outputfile = File.join(tmp_dir, "output_file.mp3")

    begin
      transcode(workingfile, output_options, outputfile)
    rescue Exceptions::BadCommand => e
      Rails.logger.error "Failed to transcode file #{e.message}"
      # requeue?
    end

    filename = "#{object_id}_mp3_web_quality.mp3"
    Storage::S3Interface.store_surrogate(object_id, outputfile, filename)

  end


  def self.executable
    Settings.plugins.ffmpeg_path
  end


  # Specify the options for the mp3 output file
  # codec, channel, bitrate, frequency, strip artwork?, strip tags?
  # settings come from the settings.yml config file
  #
  def self.output_options
    codec = "-acodec #{Settings.mp3_web_quality_out_options.codec}" unless Settings.mp3_web_quality_out_options.codec.blank?
    channel = "-ac #{Settings.mp3_web_quality_out_options.channel}" unless Settings.mp3_web_quality_out_options.channel.blank?
    bitrate = "-ab #{Settings.mp3_web_quality_out_options.bitrate}" unless Settings.mp3_web_quality_out_options.bitrate.blank?
    frequency = "-ar #{Settings.mp3_web_quality_out_options.frequency}" unless Settings.mp3_web_quality_out_options.frequency.blank?
    strip_metadata = "-map_metadata -1" if Settings.mp3_web_quality_out_options.strip_metadata.eql?("yes")
    "#{codec} #{channel} #{bitrate} #{frequency} #{strip_metadata}"
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
