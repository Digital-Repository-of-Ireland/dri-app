module FileDocument

    def preservation_only?
      key = 'dri_properties__preservation_only_tesim'
      if self[key].present? && self[key] == ["true"]
        true
      else
        false
      end
    end

    def mime_type
      self['characterization__mime_type_tesim'].present? ? self['characterization__mime_type_tesim'].first : nil
    end

    def file_format
      self['file_format_tesim'].present? ? self['file_format_tesim'].first : nil
    end

    def file_size
      self['file_size_isi'].present? ? self['file_size_isi'] : nil
    end

    def pdf?
      Settings.restrict.mime_types.pdf.include? self.mime_type
    end

    def text?
      Settings.restrict.mime_types.text.include? self.mime_type
    end

    def image?
      Settings.restrict.mime_types.image.include? self.mime_type
    end

    def video?
      Settings.restrict.mime_types.video.include? self.mime_type
    end

    def audio?
      Settings.restrict.mime_types.audio.include? self.mime_type
    end

end
