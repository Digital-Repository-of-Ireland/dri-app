# -*- encoding : utf-8 -*-
# Generated Solr Document model
#
class SolrDocument
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::AccessControls::PermissionsQuery

  include UserGroup::PermissionsSolrDocOverride
  include UserGroup::InheritanceMethods

  include DRI::Solr::Document::File
  include DRI::Solr::Document::Relations
  include DRI::Solr::Document::Documentation
  include DRI::Solr::Document::Collection
  include DRI::Solr::Document::Metadata

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
    self[ActiveFedora.index_field_mapper.solr_name('active_fedora_model', :stored_sortable, type: :string)]
  end

  def ancestor_ids
    ancestors_key = ActiveFedora.index_field_mapper.solr_name('ancestor_id', :stored_searchable, type: :string).to_sym
    return [] unless self[ancestors_key].present?    

    self[ancestors_key]
  end

  def ancestors_published?
    ancestor_ids.each do |id|
      collection = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
      doc = SolrDocument.new(collection[0])
      return false unless doc.status == 'published'
    end

    true
  end

  def collection_id
    collection_key = ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :stored_searchable, type: :symbol)

    self[collection_key].present? ? self[collection_key][0] : nil
  end

  def doi
    doi_key = ActiveFedora.index_field_mapper.solr_name('doi')

    self[doi_key]
  end

  def depositing_institute
    institute_name = ancestor_field(ActiveFedora.index_field_mapper.solr_name('depositing_institute', :displayable, type: :string))

    return Institute.find_by(name: institute_name) if institute_name

    nil
  end

  def editable?
    active_fedora_model && active_fedora_model == 'DRI::EncodedArchivalDescription' ? false : true
  end

  def file_type
    file_type_key = ActiveFedora.index_field_mapper.solr_name('file_type_display', :stored_searchable, type: :string).to_sym

    return I18n.t('dri.data.types.Unknown') if self[file_type_key].blank?

    label = FILE_TYPE_LABELS[self[file_type_key].first.to_s.downcase] || 'Unknown'

    I18n.t("dri.data.types.#{label}")
  end

  # Get the earliest ancestor for any inherited attribute
  def ancestor_field(field, ancestor = nil)
    governed_key = ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :stored_searchable, type: :symbol)

    current_doc = ancestor || self
    begin
      return current_doc[field] if current_doc[field].present?
      return nil if current_doc[governed_key].nil?
    rescue NoMethodError
      return nil
    end

    id = current_doc[governed_key].first
    ancestor_doc = ActiveFedora::SolrService.query("id:#{id}",
                                                 defType: 'edismax',
                                                 rows: '1',
                                                 fl: "id,#{governed_key},#{field}").first
    ancestor_field(field, ancestor_doc)
  end

  def has_doi?
    doi_key = ActiveFedora.index_field_mapper.solr_name('doi', :displayable, type: :symbol).to_sym

    self[doi_key].present? ? true : false
  end

  def has_geocode?
    geojson_key = ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol).to_sym

    self[geojson_key].present? ? true : false
  end

  def icon_path
    key = ActiveFedora.index_field_mapper.solr_name('file_type_display', :stored_searchable, type: :string).to_sym
    format = self[key].first.to_s.downcase

    icon = if %w(image audio text video mixed_types).include?(format)
             "dri/formats/#{format}_icon.png"
           else
             'no_image.png'
           end

    icon
  end

  def collection?
    is_collection_key = ActiveFedora.index_field_mapper.solr_name('is_collection')

    return false unless self[is_collection_key].present?

    is_collection = if self[is_collection_key].is_a?(Array)
                      self[is_collection_key].first
                    else
                      self[is_collection_key]
                    end

    is_collection == 'true' || is_collection == true ? true : false
  end

  def root_collection?
    collection_id ? false : true
  end

  def sub_collection?
    collection? && !root_collection?
  end

  def institutes
    institute_names = ancestor_field(ActiveFedora.index_field_mapper.solr_name('institute', :stored_searchable, type: :string))
    institutes = Institute.where(name: institute_names)

    institutes.to_a 
  end

  def licence
    licence_key = ActiveFedora.index_field_mapper.solr_name('licence', :stored_searchable, type: :string).to_sym

    if self[licence_key].present?
      licence = Licence.where(name: self[licence_key]).first
      licence ||= self[licence_key]
    else
      licence = retrieve_ancestor_licence
    end

    licence
  end

  def object_profile
    key = ActiveFedora.index_field_mapper.solr_name('object_profile', :displayable)

    self[key].present? ? JSON.parse(self[key].first) : {}
  end

  def root_collection
    root_key = ActiveFedora.index_field_mapper.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym
    root = nil
    if self[root_key].present?
      id = self[root_key][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, defType: 'edismax', rows: '1')
      root = SolrDocument.new(collection[0])
    end

    root
  end

  def governing_collection
    governing_id = collection_id
    return nil unless governing_id

    solr_query = "id:#{governing_id}"
    collection = ActiveFedora::SolrService.query(solr_query, defType: 'edismax', rows: '1')
    
    SolrDocument.new(collection[0])
  end

  def retrieve_ancestor_licence
    ancestors_key = ActiveFedora.index_field_mapper.solr_name('ancestor_id', :stored_searchable, type: :string).to_sym
    return nil unless self[ancestors_key].present?

    licence_key = ActiveFedora.index_field_mapper.solr_name('licence', :stored_searchable, type: :string).to_sym

    ancestors_ids = self[ancestors_key]
    ancestors_ids.each do |id|
      collection = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
      doc = SolrDocument.new(collection[0])
      return Licence.where(name: doc[licence_key]).first if doc[licence_key].present?
    end

    nil
  end

  def status
    status_key = ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :string).to_sym

    self[status_key].first
  end

  def published?
    ancestors_published? && status == 'published'
  end

  def public_read?
    read_access_groups_key = ActiveFedora.index_field_mapper.solr_name('read_access_group', :stored_searchable, type: :symbol)
    groups = get_permission_key(self.id, read_access_groups_key)
    return false if groups.nil? #groups could be nil if read access set to restricted

    groups.include?(SETTING_GROUP_PUBLIC)
  end

  def permissions_doc(id)
    get_permissions_solr_response_for_doc_id(id)
  end

  def draft?
    status == 'draft'
  end
end
