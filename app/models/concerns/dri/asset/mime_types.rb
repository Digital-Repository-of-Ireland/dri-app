module DRI
  module Asset
    module MimeTypes
      extend ActiveSupport::Concern

      def pdf?
        self.class.pdf_mime_types.include? (self.mime_type) && !self.class.restricted_3D_extensions.include?(extension)
      end

      def text?
        self.class.text_mime_types.include?(self.mime_type) && self.class.restricted_text_extensions.include?(extension)
      end

      def image?
        self.class.image_mime_types.include? (self.mime_type) && !self.class.restricted_3D_extensions.include?(extension)
      end

      def video?
        self.class.video_mime_types.include? (self.mime_type)
      end

      def audio?
        self.class.audio_mime_types.include? (self.mime_type)
      end

      def threeD
        self.class._3D_mime_types.include?(self.mime_type) && !self.class.restricted_text_extensions.include?(extension) && self.class._3D_file_formats.any?{ |f| self.file_format.downcase.include?(f.downcase)}
      end

      def file_format
        return nil if self.mime_type.blank? && self.format_label.blank?
        return self.mime_type.split('/')[1] + " (" + self.format_label.join(", ") + ")" unless self.mime_type.blank? || self.format_label.blank?
        return self.mime_type.split('/')[1] unless self.mime_type.blank?
        return self.format_label
      end

      def extension
        File.extname(self.label).downcase if self.label
      end

      module ClassMethods
        def image_mime_types
          Settings.restrict.mime_types.image
        end

        def pdf_mime_types
          Settings.restrict.mime_types.pdf
        end

        def text_mime_types
          Settings.restrict.mime_types.text
        end

        def video_mime_types
          Settings.restrict.mime_types.video
        end

        def audio_mime_types
          Settings.restrict.mime_types.audio
        end

        def _3D_mime_types
          Settings.restrict.mime_types._3D
        end

        # Restrict mimetypes for 3D
        def _3D_file_formats
          ::Settings.restrict.file_formats._3D
        end

        def restricted_text_extensions
          ::Settings.restrict.extensions.restricted_text
        end

        def restricted_3D_extensions
          ::Settings.restrict.extensions.restricted_3D
        end

      end
    end
  end
end
