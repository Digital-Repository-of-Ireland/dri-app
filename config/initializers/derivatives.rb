
DRI::Asset::Derivatives.module_eval do
  def create_derivatives(_filename)
    case mime_type
    when *self.class.pdf_mime_types
      Hydra::Derivatives::PdfDerivatives.create(self, source: :content,
        outputs: [
          { label: :thumbnail_medium, format: 'jpg', size: '200', trim: 'true', object: self.batch.id, file: self.id, layer: 0 },
          { label: :thumbnail_large, format: 'jpg', size: '400', trim: 'true', object: self.batch.id, file: self.id, layer: 0 },
          { label: :lightbox_format, format: 'jpg', size: '600', object: self.batch.id, file: self.id, layer: 0 },
          { label: :full_size_web_format, format: 'jpg', size: '100%', object: self.batch.id, file: self.id, layer: 0 },
          { label: :crop16_9_width_200_thumbnail, size: '200', crop: '200x113+0+0', gravity: "Center", trim: true, object: self.batch.id, file: self.id, layer: 0 }
        ]
      )
    when *self.class.text_mime_types
      Hydra::Derivatives::DocumentDerivatives.create(self, source: :content,
        outputs: [{ format: 'pdf', label: :pdf, object: self.batch.id, file: self.id }]
      )
    when *self.class.audio_mime_types
      Hydra::Derivatives::AudioDerivatives.create(self, source: :content,
        outputs: [
          { format: 'mp3', label: :mp3, object: self.batch.id, file: self.id },
          { format: 'ogg', label: :ogg, object: self.batch.id, file: self.id }
        ]
      )
    when *self.class.video_mime_types
      Hydra::Derivatives::VideoDerivatives.create(self, source: :content,
        outputs: [
          { format: 'webm', label: :webm, object: self.batch.id, file: self.id },
          { format: 'mp4', label: :mp4, object: self.batch.id, file: self.id },
          { format: 'jpg', label: :thumbnail, object: self.batch.id, file: self.id }
        ]
      )
    when *self.class.image_mime_types
      Hydra::Derivatives::ImageDerivatives.create(self, source: :content,
        outputs: [
          { label: :thumbnail_medium, format: 'jpg', size: '200', trim: 'true', object: self.batch.id, file: self.id },
          { label: :thumbnail_large, format: 'jpg', size: '400', trim: 'true', object: self.batch.id, file: self.id },
          { label: :lightbox_format, format: 'jpg', size: '600', object: self.batch.id, file: self.id },
          { label: :full_size_web_format, format: 'jpg', size: '100%', object: self.batch.id, file: self.id },
          { label: :crop16_9_width_200_thumbnail, format: 'jpg', size: '200', crop: '200x113+0+0', gravity: "Center", trim: true, object: self.batch.id, file: self.id },
          { label: :optimized_web_format, format: 'jpg', size: '980>', object: self.batch.id, file: self.id }
        ]
      )
    end
  end
end
