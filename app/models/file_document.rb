module FileDocument

    def preservation_only?
      key = 'dri_properties__preservation_only_tesim'
      
      (self[key].present? && self[key] == ["true"]) ? true : false
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

    def read_master?
      master_file_key = ActiveFedora::SolrQueryBuilder.solr_name('master_file_access', :stored_searchable, type: :string)

      governing_object = self

      while governing_object[master_file_key].nil? || governing_object[master_file_key] == "inherit"
        parent_id = governing_object[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)]
        return false unless parent_id
      
        parent_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([parent_id.first])
    
        parent = ActiveFedora::SolrService.query(parent_query)
        governing_object = SolrDocument.new(parent.first)      
      end

      governing_object[master_file_key] == ["public"]
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
