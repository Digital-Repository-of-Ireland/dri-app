module DRI::Solr::Document::File
  def assets(with_preservation = false)
    files_query = "active_fedora_model_ssi:\"DRI::GenericFile\""
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{id}\""

    unless with_preservation
      files_query += " AND NOT #{ActiveFedora.index_field_mapper.solr_name('dri_properties__preservation_only', :stored_searchable)}:true"
    end
    query = Solr::Query.new(files_query)

    assets = []
    query.each_solr_document { |sd| assets << sd }

    assets
  end

  def preservation_only?
    key = 'dri_properties__preservation_only_tesim'

    self[key].present? && self[key] == ['true'] ? true : false
  end

  def mime_type
    mime_key = 'characterization__mime_type_tesim'
    self[mime_key].present? ? self[mime_key].first : nil
  end

  def file_format
    self['file_format_tesim'].present? ? self['file_format_tesim'].first : nil
  end

  def file_size
    self['file_size_isi'].present? ? self['file_size_isi'] : nil
  end

  def pdf?
    Settings.restrict.mime_types.pdf.include? mime_type
  end

  def supported_type?
    mime_type.nil? || (audio? ||
      video? || pdf? || image? ||
      text? && file_format.include?("RTF"))
  end

  def read_master?
    master_file_key = ActiveFedora.index_field_mapper.solr_name('master_file_access', :stored_searchable, type: :string)

    governing_object = self

    while governing_object[master_file_key].nil? || governing_object[master_file_key] == 'inherit'
      parent_id = governing_object[ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :stored_searchable, type: :symbol)]
      return false unless parent_id

      governing_object = parent_object(parent_id.first)
    end

    governing_object[master_file_key] == ['public']
  end

  def surrogates(file_id, timeout = nil)
    storage = StorageService.new
    storage.get_surrogates(self, file_id, timeout)
  end

  def text?
    Settings.restrict.mime_types.text.include? mime_type
  end

  def image?
    Settings.restrict.mime_types.image.include? mime_type
  end

  def video?
    Settings.restrict.mime_types.video.include? mime_type
  end

  def audio?
    Settings.restrict.mime_types.audio.include? mime_type
  end

  private

    def parent_object(id)
      parent_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])
      parent = ActiveFedora::SolrService.query(parent_query)
      SolrDocument.new(parent.first)
    end
end
