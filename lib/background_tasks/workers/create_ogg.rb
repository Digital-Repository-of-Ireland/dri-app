class CreateOgg
  @queue = "create_ogg_queue"

  require 'open3'

  def self.perform(object_id)
    puts "Creating Ogg version of #{object_id} asset, if required"

    datastream = "masterContent"
    @object = ActiveFedora::Base.find(object_id,{:cast => true})
    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                             { :f => @object.id, :d => datastream } ],
                                      :order => "version DESC",
                                      :limit => 1)
    masterfile = @local_file_info.first.path

    tmp_dir = File.join(Dir::tmpdir, "dri_ogg_#{Time.now.to_i}_#{rand(100)}")
    Dir.mkdir(tmp_dir)
    workingfile = File.join(tmp_dir, File.basename(masterfile))
    FileUtils.cp(masterfile,workingfile)
    outputfile = File.join(tmp_dir, "output_file.ogg")

    transcode(workingfile, output_options, outputfile)

    # Add the file to the object somehow...

  end


  def self.executable
    Settings.plugins.ffmpeg_path
  end


  # Specify the options for the ogg output file
  # codec, channel, bitrate, frequency, strip artwork?, strip tags?
  # settings come from the settings.yml config file
  #
  def self.output_options
    codec = "-acodec #{Settings.ogg_out_options.codec}" unless Settings.ogg_out_options.codec.blank?
    channel = "-ac #{Settings.ogg_out_options.channel}" unless Settings.ogg_out_options.channel.blank?
    bitrate = "-ab #{Settings.ogg_out_options.bitrate}" unless Settings.ogg_out_options.bitrate.blank?
    frequency = "-ar #{Settings.ogg_out_options.frequency}" unless Settings.ogg_out_options.frequency.blank?
    strip_metadata = "-map_metadata -1" if Settings.ogg_out_options.strip_metadata.eql?("yes")
    "#{codec} -vn #{channel} #{bitrate} #{frequency} #{strip_metadata}"
  end


  # Transcode the file
  def self.transcode(input_file, options, output_file)
    command = "#{executable} -i #{input_file} #{options} #{output_file}"
    stdin, stdout, stderr, wait_thr = Open3::popen3(command)
    stdin.close
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close
    raise "Unable to execute command \"#{command}\"\n#{err}" unless wait_thr.value.success?
  end


end
