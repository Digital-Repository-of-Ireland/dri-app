module Sufia
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        include Hydra::Derivatives

        makes_derivatives do |obj|
          case obj.mime_type
          when *pdf_mime_types
            obj.transform_datastream :content,
              { :large => {size: "400", datastream: 'thumbnail_large'},
              	:lightbox => {size: "600", datastream: 'lightbox_format'}
               }
          when *audio_mime_types
            obj.transform_datastream :content,
              { :mp3 => {format: 'mp3', datastream: 'mp3'},
                :ogg => {format: 'ogg', datastream: 'ogg'} }, processor: :audio
          when *video_mime_types
            obj.transform_datastream :content,
              { :webm => {format: "webm", datastream: 'webm'},
                :mp4 => {format: "mp4", datastream: 'mp4'} }, processor: :video
          when *image_mime_types
            obj.transform_datastream :content,
              { 
                :small => {size: "75", datastream: 'thumbnail_small'},
                :medium => {size: "200", datastream: 'thumbnail_medium'},
                :large => {size: "400", datastream: 'thumbnail_large'},
                :lightbox => {size: "600", datastream: 'lightbox_format'},
                :full => {size: "100%", datastream: 'full_size_web_format'},
                :crop16_9_width_200 => {size: "200", crop: "200x113+0+0", gravity: "Center", datastream: 'crop16_9_width_200_thumbnail'},
                :crop16_9_width_2228 => {size: "228", crop: "228x127+0+0", gravity: "Center", datastream: 'crop16_9_width_228_thumbnail'} 
              }
          end
        end
      end

    end
  end
end
