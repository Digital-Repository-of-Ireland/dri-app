# -*- encoding : utf-8 -*-
# Generated Solr Document model
#
class SolrDocument

  include Blacklight::Document
  include UserGroup::PermissionsSolrDocOverride
  include DRI::Solr::Document::File
  include DRI::Solr::Document::Relations
  include DRI::Solr::Document::Documentation

  # DublinCore uses the semantic field mappings below to assemble
  # an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See
  # Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  field_semantics.merge!(
    title: 'title_display',
    author: 'author_display',
    language: 'language_facet',
    format: 'format'
  )

  FILE_TYPE_LABELS = {
    'image' => 'Image',
    'audio' => 'Sound',
    'video' => 'MovingImage',
    'text' => 'Text',
    'mixed_types' => 'MixedType'
  }

  def active_fedora_model
    self[ActiveFedora::SolrQueryBuilder.solr_name('active_fedora_model', :stored_sortable, type: :string)]
  end

  def collection_id
    collection_key = ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)

    self[collection_key].present? ? self[collection_key][0] : nil
  end

  def doi
    doi_key = ActiveFedora::SolrQueryBuilder.solr_name('doi')

    self[doi_key]
  end

  def editable?
    (active_fedora_model && active_fedora_model == 'DRI::EncodedArchivalDescription') ? false : true
  end

  def file_type
    file_type_key = ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable, type: :string).to_sym

    return I18n.t('dri.data.types.Unknown') if self[file_type_key].blank?

    label = FILE_TYPE_LABELS[self[file_type_key].first.to_s.downcase] || 'Unknown'

    I18n.t("dri.data.types.#{label}")
  end

  def has_doi?
    doi_key = ActiveFedora::SolrQueryBuilder.solr_name('doi', :displayable, type: :symbol).to_sym

    self[doi_key].present? ? true : false
  end

  def has_geocode?
    geojson_key = ActiveFedora::SolrQueryBuilder.solr_name('geojson', :stored_searchable, type: :symbol).to_sym

    self[geojson_key].present? ? true : false
  end

  def icon_path
    key = ActiveFedora::SolrQueryBuilder.solr_name('file_type_display', :stored_searchable, type: :string).to_sym
    format = self[key].first.to_s.downcase

    if %w(image audio text video mixed_types).include?(format)
      icon = "dri/formats/#{format}_icon.png"
    else
      icon = 'no_image.png'
    end

    icon
  end

  def is_collection?
    is_collection_key = ActiveFedora::SolrQueryBuilder.solr_name('is_collection')
    
    self[is_collection_key].present? && self[is_collection_key].include?("true")
  end

  def is_root_collection?
    collection_id ? false : true  
  end

  def licence
    licence_key = ActiveFedora::SolrQueryBuilder.solr_name('licence', :stored_searchable, type: :string).to_sym

    if self[licence_key].present?
      licence = Licence.where(name: self[licence_key]).first
      licence ||= self[licence_key]
    elsif root_collection
      collection = root_collection
      licence = Licence.where(name: collection[licence_key]).first if collection[licence_key].present?
    end
    
    licence
  end

  def object_profile
    key = ActiveFedora::SolrQueryBuilder.solr_name('object_profile', :displayable)

    self[key].present? ? JSON.parse(self[key].first) : {}
  end

  def root_collection
    root_key = ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym
    root = nil
    if self[root_key].present?
      id = self[root_key][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, defType: 'edismax', rows: '1')
      root = SolrDocument.new(collection[0])
    end
    
    root
  end
  
  def status
    status_key = ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :string).to_sym

    self[status_key].first
  end

  def published?
    status == 'published'
  end

  def draft?
    status == 'draft'
  end

end
