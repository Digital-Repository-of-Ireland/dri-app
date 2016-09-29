module Sufia
  module GenericFile
    module MimeTypes
      extend ActiveSupport::Concern

      def pdf?
        self.class.pdf_mime_types.include? self.mime_type
      end

      def text?
        self.class.text_mime_types.include? self.mime_type
      end

      def image?
        self.class.image_mime_types.include? self.mime_type
      end

      def video?
        self.class.video_mime_types.include? self.mime_type
      end

      def audio?
        self.class.audio_mime_types.include? self.mime_type
      end

      def file_format
        return nil if self.mime_type.blank? && self.format_label.blank?
        return self.mime_type.split('/')[1] + " (" + self.format_label.join(", ") + ")" unless self.mime_type.blank? || self.format_label.blank?
        return self.mime_type.split('/')[1] unless self.mime_type.blank?
        return self.format_label
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
      end
    end
  end
end
