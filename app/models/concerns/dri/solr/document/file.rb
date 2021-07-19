module DRI::Solr::Document::File

  def assets(with_preservation: false, ordered: false)
    files_query = "isPartOf_ssim:\"#{alternate_id}\""

    fq = 'active_fedora_model_ssi:"DRI::GenericFile"'
    fq << '-preservation_only_ssi:true' unless with_preservation

    query = ::Solr::Query.new(files_query, 100, { fq: fq })
    assets = query.to_a
    ordered ? sort_assets(assets) : assets
  end

  def characterized?
    # not characterized if all empty
    return false unless self.key?('mime_type_tesim')

    self['mime_type_tesim'].any? { |m| m.present? }
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
    key = 'preservation_only_ssi'
    self[key].present? && self[key] == 'true' ? true : false
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
    self['file_size_ltsi'].present? ? self['file_size_ltsi'] : nil
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
    return @read_master if @read_master

    master_file_key = 'master_file_access_ssi'
    return true if self[master_file_key] == 'public'
    return false if self[master_file_key] == 'private'

    result = false
    ancestor_ids.each do |id|
      ancestor = ancestor_docs[id]
      next if ancestor[master_file_key].nil? || ancestor[master_file_key].include?('inherit')

      result = ancestor[master_file_key] == 'public' ? true : false
      break
    end

    @read_master = result
    @read_master
  end

  def surrogates(file_id, timeout = nil)
    @cache ||= {}
    @cache[file_id] ||= storage_service.get_surrogates(self, file_id, timeout)
  end

  def surrogates_list
    @surrogates_list ||= storage_service.list_surrogates(alternate_id)
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
