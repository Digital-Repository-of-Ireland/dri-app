DRI::Asset::Derivatives.module_eval do
  def create_derivatives(_filename)
    case mime_type
    when *self.class.pdf_mime_types
      Hydra::Derivatives::PdfDerivatives.create(self, source: :content,
        outputs: [
          { label: :thumbnail_medium, format: 'jpg', size: '200', trim: 'true', object: self.digital_object.alternate_id, file: self.alternate_id, layer: 0 },
          { label: :thumbnail_large, format: 'jpg', size: '400', trim: 'true', object: self.digital_object.alternate_id, file: self.alternate_id, layer: 0 },
          { label: :lightbox_format, format: 'jpg', size: '600', object: self.digital_object.alternate_id, file: self.alternate_id, layer: 0 },
          { label: :full_size_web_format, format: 'jpg', size: '100%', object: self.digital_object.alternate_id, file: self.alternate_id, layer: 0 },
          { label: :crop16_9_width_200_thumbnail, size: '200', crop: '200x113+0+0', gravity: "Center", trim: true, object: self.digital_object.alternate_id, file: self.alternate_id, layer: 0 }
        ]
      )
    when *self.class.text_mime_types
      Hydra::Derivatives::DocumentDerivatives.create(self, source: :content,
        outputs: [{ format: 'pdf', label: :pdf, object: self.digital_object.alternate_id, file: self.alternate_id }]
      )
    when *self.class.audio_mime_types
      Hydra::Derivatives::AudioDerivatives.create(self, source: :content,
        outputs: [
          { format: 'mp3', label: :mp3, object: self.digital_object.alternate_id, file: self.alternate_id },
          { format: 'ogg', label: :ogg, object: self.digital_object.alternate_id, file: self.alternate_id }
        ]
      )
    when *self.class.video_mime_types
      Hydra::Derivatives::VideoDerivatives.create(self, source: :content,
        outputs: [
          { format: 'webm', label: :webm, object: self.digital_object.alternate_id, file: self.alternate_id },
          { format: 'mp4', label: :mp4, object: self.digital_object.alternate_id, file: self.alternate_id },
          { format: 'jpg', label: :thumbnail, object: self.digital_object.alternate_id, file: self.alternate_id }
        ]
      )
    when *self.class.image_mime_types
      Hydra::Derivatives::ImageDerivatives.create(self, source: :content,
        outputs: [
          { label: :thumbnail_medium, format: 'jpg', size: '200', trim: 'true', object: self.digital_object.alternate_id, file: self.alternate_id },
          { label: :thumbnail_large, format: 'jpg', size: '400', trim: 'true', object: self.digital_object.alternate_id, file: self.alternate_id },
          { label: :lightbox_format, format: 'jpg', size: '600', object: self.digital_object.alternate_id, file: self.alternate_id },
          { label: :full_size_web_format, format: 'jpg', size: '100%', object: self.digital_object.alternate_id, file: self.alternate_id },
          { label: :crop16_9_width_200_thumbnail, format: 'jpg', resize_and_pad: '200x113', object: self.digital_object.alternate_id, file: self.alternate_id },
          { label: :optimized_web_format, format: 'jpg', size: '980>', object: self.digital_object.alternate_id, file: self.alternate_id }
        ]
      )
    end
  end
end
