# frozen_string_literal: true
module DRI::Derivatives::Processors
  module Video
    class Processor < Hydra::Derivatives::Processors::Video::Processor
      def options_for(format)
        output_options = if config.size_attributes.start_with?('scale=')
                           "-vf #{config.size_attributes}"
                         else
                           "-s #{config.size_attributes} #{codecs(format)}"
                         end
        output_options += " #{codecs(format)}"

        if format == "jpg"
          input_options = " -itsoffset -2"
          output_options += " -vframes 1 -an -f rawvideo"
        else
          input_options = ''
          output_options += " #{config.video_attributes} #{config.audio_attributes}"
        end

        ffmpeg_options(output_options, input_options)
      end

      def ffmpeg_options(output_options, input_options)
        {
          Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => output_options,
          Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => input_options
        }
      end
    end
  end
end
