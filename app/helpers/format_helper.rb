module FormatHelper
  def collection?(document)
    has_type?('collection', document)
  end

  def audio?(document)
    has_type?('audio', document)
  end

  def image?(document)
    has_type?('image', document)
  end

  def video?(document)
    has_type?('video', document)
  end

  def document?(document)
    has_type?('text', document)
  end

  def has_type?(type, document)
    type.casecmp(format?(document)).zero? ? true : false
  end

  def format?(document)
    if document[ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)].present?
      document[ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)].first
    else
      'unknown'
    end
  end
end
