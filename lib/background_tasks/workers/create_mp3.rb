class CreateMp3 < CreateAudio
  @queue = "create_mp3_queue"
  @type = "mp3"

  require 'open3'
  require 'tempfile'
  require 'storage/s3_interface'

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

end
