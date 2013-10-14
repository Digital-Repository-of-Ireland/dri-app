class CreateOgg < CreateAudio
  @queue = "create_ogg_queue"
  @type = "ogg"

  require 'open3'
  require 'storage/s3_interface'

  # Specify the options for the ogg output file
  # codec, channel, bitrate, frequency, strip artwork?, strip tags?
  # settings come from the settings.yml config file
  #
  def self.output_options
    codec = "-acodec #{Settings.ogg_web_quality_out_options.codec}" unless Settings.ogg_web_quality_out_options.codec.blank?
    channel = "-ac #{Settings.ogg_web_quality_out_options.channel}" unless Settings.ogg_web_quality_out_options.channel.blank?
    bitrate = "-ab #{Settings.ogg_web_quality_out_options.bitrate}" unless Settings.ogg_web_quality_out_options.bitrate.blank?
    frequency = "-ar #{Settings.ogg_web_quality_out_options.frequency}" unless Settings.ogg_web_quality_out_options.frequency.blank?
    strip_metadata = "-map_metadata -1" if Settings.ogg_web_quality_out_options.strip_metadata.eql?("yes")
    "#{codec} -vn #{channel} #{bitrate} #{frequency} #{strip_metadata}"
  end

end
