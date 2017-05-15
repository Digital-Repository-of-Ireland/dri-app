module DRI
  module Asset
    module Derivatives
      extend ActiveSupport::Concern

      included do
        include Hydra::Derivatives

        makes_derivatives do |obj|
          case obj.mime_type
          when *pdf_mime_types
            obj.transform_file :content,
              {
                #:small => {size: "75", datastream: 'thumbnail_small'},
                medium: { size: "200", trim: "true", datastream: 'thumbnail_medium' },
                large: { size: "400", trim: "true", datastream: 'thumbnail_large' },
                lightbox: { size: "600", datastream: 'lightbox_format' },
                full: { size: "100%", datastream: 'full_size_web_format' },
                crop16_9_width_200: { size: "200", crop: "200x113+0+0", gravity: "Center", trim: "true", datastream: 'crop16_9_width_200_thumbnail' }
              }
          when *audio_mime_types
            obj.transform_file :content,
              { mp3: { format: 'mp3', datastream: 'mp3' },
                ogg: { format: 'ogg', datastream: 'ogg' } }, processor: :audio
          when *video_mime_types
            obj.transform_file :content,
              { webm: { format: "webm", datastream: 'webm' },
                mp4: { format: "mp4", datastream: 'mp4' } }, processor: :video
          when *image_mime_types
            obj.transform_file :content,
              {
                #:small => {size: "75", datastream: 'thumbnail_small', format: 'jpg'},
                medium: { size: "200", datastream: 'thumbnail_medium', format: 'jpg' },
                large: { size: "400", datastream: 'thumbnail_large', format: 'jpg' },
                lightbox: { size: "600", datastream: 'lightbox_format', format: 'jpg' },
                full: { size: "100%", datastream: 'full_size_web_format', format: 'jpg' },
                optimized: { size: "980>", datastream: 'optimized_web_format', format: 'jpg' },
                crop16_9_width_200: { size: "200", crop: "200x113+0+0", gravity: "Center", datastream: 'crop16_9_width_200_thumbnail', format: 'jpg' }
              }
          end
        end
      end

    end
  end
end
