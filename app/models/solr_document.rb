# -*- encoding : utf-8 -*-
# Generated Solr Document model
#
class SolrDocument
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::AccessControls::PermissionsQuery
  include BlacklightOaiProvider::SolrDocument

  include UserGroup::PermissionsSolrDocOverride
  include UserGroup::InheritanceMethods

  include DRI::Solr::Document::File
  include DRI::Solr::Document::Relations
  include DRI::Solr::Document::Documentation
  include DRI::Solr::Document::Collection
  include DRI::Solr::Document::Metadata
  include DRI::Solr::Document::Oai

  # DublinCore uses the semantic field mappings below to assemble
  # an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See
  # Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  field_semantics.merge!(
    title: 'title_tesim',
    description: 'description_tesim',
    creator: 'creator_tesim',
    publisher: 'publisher_tesim',
    subject: 'subject_tesim',
    type: 'type_tesim',
    language: 'language_tesim',
    format: 'file_type_tesim',
    rights: 'rights_tesim',
  )

  def self.find(id)
    result = ActiveFedora::SolrService.query("id:#{id}")
    SolrDocument.new(result.first) if result.present?
  end

  def active_fedora_model
    self[ActiveFedora.index_field_mapper.solr_name('active_fedora_model', :stored_sortable, type: :string)]
  end

  def ancestor_docs
    @ancestor_docs ||= load_ancestors
  end

  def load_ancestors
    ids = ancestor_ids
    if ids.present?
      docs = {}
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids)
      results = ActiveFedora::SolrService.query(query)
      results.each { |r| docs[r['id']] = SolrDocument.new(r) }
    end

    docs
  end

  # Get the earliest ancestor for any inherited attribute
  def ancestor_field(field)
    return self[field] if self[field].present?

    return nil unless ancestor_docs.present?

    ancestor_ids.each do |ancestor_id|
      ancestor = ancestor_docs[ancestor_id]
      return ancestor[field] if ancestor[field].present?
    end

    nil
  end

  def ancestor_ids
    ancestors_key = ActiveFedora.index_field_mapper.solr_name('ancestor_id', :stored_searchable, type: :string).to_sym
    return [] unless self[ancestors_key].present?

    self[ancestors_key]
  end

  def ancestors_published?
    ancestor_ids.each do |id|
      doc = ancestor_docs[id]
      return false unless doc.status == 'published'
    end

    true
  end

  def collection_id
    collection_key = ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :stored_searchable, type: :symbol)

    self[collection_key].present? ? self[collection_key][0] : nil
  end

  def contains_images?
    files_query = "active_fedora_model_ssi:\"DRI::GenericFile\""
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name('isPartOf', :symbol)}:#{id}"
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name('file_type', :facetable)}:\"image\""

    ActiveFedora::SolrService.count(files_query) > 0
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

  def has_doi?
    doi_key = ActiveFedora.index_field_mapper.solr_name('doi', :displayable, type: :symbol).to_sym

    self[doi_key].present? ? true : false
  end

  def has_geocode?
    geojson_key = ActiveFedora.index_field_mapper.solr_name('geojson', :stored_searchable, type: :symbol).to_sym

    self[geojson_key].present? ? true : false
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

    licence = if self[licence_key].present?
      Licence.where(name: self[licence_key]).first || self[licence_key]
    else
      retrieve_ancestor_licence
    end

    licence
  end

  def object_profile
    key = ActiveFedora.index_field_mapper.solr_name('object_profile', :displayable)

    self[key].present? ? JSON.parse(self[key].first) : {}
  end

  def root_collection_id
    root_key = ActiveFedora.index_field_mapper.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym

    self[root_key].present? ? self[root_key].first : nil
  end

  def root_collection
    root_id = root_collection_id
    return self if root_id && ancestor_docs.blank?

    root = ancestor_docs[root_id] if root_id && ancestor_docs.key?(root_id)
    root
  end

  def governing_collection
    governing_id = collection_id
    return nil unless governing_id

    ancestor_docs[governing_id]
  end

  def retrieve_ancestor_licence
    ancestors_key = ActiveFedora.index_field_mapper.solr_name('ancestor_id', :stored_searchable, type: :string).to_sym
    return nil unless ancestor_docs.present?

    licence_key = ActiveFedora.index_field_mapper.solr_name('licence', :stored_searchable, type: :string).to_sym

    ancestor_ids.each do |id|
      doc = ancestor_docs[id]
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
