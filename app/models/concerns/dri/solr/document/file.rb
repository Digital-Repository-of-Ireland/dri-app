module DRI::Solr::Document::File

  def assets(with_preservation: false, ordered: false)
    files_query = "active_fedora_model_ssi:\"DRI::GenericFile\""
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{id}\""

    query = ::Solr::Query.new(files_query)
    assets = query.reject { |sd| with_preservation == false && sd.preservation_only? }
    ordered ? sort_assets(assets) : assets
  end

  def characterized?
    # not characterized if all empty
    self['characterization__mime_type_tesim'].present? && !self['characterization__mime_type_tesim'].all? { |m| m.empty? }
  end

  def sort_assets(assets)
    assets.sort do |a,b|
      DRI::Sorters.trailing_digits_sort(
        File.basename(a.label, File.extname(a.label)),
        File.basename(b.label, File.extname(b.label))
      )
    end
  end

  def preservation_only?
    key = 'preservation_only_tesim'

    self[key].present? && self[key] == ['true'] ? true : false
  end

  def label
    self['label_tesim'].present? ? self['label_tesim'].first : ''
  end

  def mime_type
    mime_key = 'mime_type_tesim'
    self[mime_key].present? ? self[mime_key].first : nil
  end

  def file_format
    self['file_format_tesim'].present? ? self['file_format_tesim'].first : nil
  end

  def file_size
    self['file_size_isi'].present? ? self['file_size_isi'] : nil
  end

  def file_types
    self['file_type_display_tesim'] || []
  end

  def supported_type?
    mime_type.nil? || (audio? ||
      video? || pdf? || image? ||
      text? || threeD? && (file_format.include?('RTF') || file_format.include?('msword')))
  end

  def read_master?
    master_file_key = ActiveFedora.index_field_mapper.solr_name('master_file_access', :stored_searchable, type: :string)
    return true if self[master_file_key] == ['public']
    return false if self[master_file_key] == ['private']

    result = false

    ancestor_ids.each do |id|
      ancestor = ancestor_docs[id]
      next if ancestor[master_file_key].nil? || ancestor[master_file_key].include?('inherit')

      result = ancestor[master_file_key] == ['public'] ? true : false
      break
    end

    result
  end

  def surrogates(file_id, timeout = nil)
    storage_service.get_surrogates(self, file_id, timeout)
  end

  def storage_service
    @storage_service ||= StorageService.new
  end

  def text?
    Settings.restrict.mime_types.text.include? mime_type
  end

  def image?
    Settings.restrict.mime_types.image.include? mime_type
  end

  def pdf?
    Settings.restrict.mime_types.pdf.include? mime_type
  end

  def video?
    Settings.restrict.mime_types.video.include? mime_type
  end

  def audio?
    Settings.restrict.mime_types.audio.include? mime_type
  end

  def threeD?
   Settings.restrict.mime_types._3D.include?(mime_type) &&
     Settings.restrict.file_formats._3D.any?{ |f| file_format.downcase.include?(f.downcase) }
  end

end
