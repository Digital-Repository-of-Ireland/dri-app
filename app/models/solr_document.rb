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
    Solr::Query.find(id)
  end

  def active_fedora_model
    self[Solrizer.solr_name('active_fedora_model', :stored_sortable, type: :string)]
  end

  def ancestor_docs
    @ancestor_docs ||= load_ancestors
  end

  def load_ancestors
    ids = ancestor_ids
    if ids.present?
      docs = {}
      query = Solr::Query.construct_query_for_ids(ids)
      results = Solr::Query.new(query, 100, { rows: ids.length }).to_a
      results.each { |r| docs[r['id']] = r }
    end

    docs
  end

  # Get the earliest ancestor for any inherited attribute
  def ancestor_field(field)
    return self[field] if self[field].present?

    return nil unless ancestor_docs.present?

    ancestor_ids.each do |ancestor_id|
      ancestor = ancestor_docs[ancestor_id]
      return ancestor[field] if ancestor && ancestor[field].present?
    end

    nil
  end

  def ancestor_ids
    ancestors_key = 'ancestor_id_ssim'.to_sym
    return [] unless self[ancestors_key].present?

    self[ancestors_key]
  end

  def ancestors_published?
    ancestor_ids.each do |id|
      doc = ancestor_docs[id]
      return false unless doc&.status == 'published'
    end

    true
  end

  def collection_id
    collection_key = 'isGovernedBy_ssim'

    self[collection_key].present? ? self[collection_key][0] : nil
  end

  def contains_images?
    files_query = "active_fedora_model_ssi:\"DRI::GenericFile\""
    files_query += " AND #{Solrizer.solr_name('isPartOf', :symbol)}:#{id}"
    files_query += " AND #{Solrizer.solr_name('file_type', :facetable)}:\"image\""

    Solr::Query.new(files_query).count > 0
  end

  def doi
    self['doi_ss']
  end

  def depositing_institute
    institute_name = ancestor_field('depositing_institute_ssi')

    return Institute.find_by(name: institute_name) if institute_name

    nil
  end

  def editable?
    active_fedora_model && active_fedora_model == 'DRI::EncodedArchivalDescription' ? false : true
  end

  def has_doi?
    doi_key = 'doi_ss'.to_sym

    self[doi_key].present?
  end

  def has_geocode?
    geojson_key = Solrizer.solr_name('geojson', :stored_searchable, type: :symbol).to_sym

    self[geojson_key].present?
  end

  # @param [String] field_name
  # @return [Boolean]
  def truthy_index_field?(key)
    return false unless self[key].present?
    value = if self[key].is_a?(Array)
              self[key].first
            else
              self[key]
            end
    value == 'true' || value == true
  end

  # legacy from sufia, all objects / collections have model DRI::Batch
  # Generic files are DRI::GenericFile
  # @return [Boolean]
  def digital_object?
    self['has_model_ssim'].include?("DRI::DigitalObject")
  end

  # @return [Boolean]
  def generic_file?
    self['has_model_ssim'].include?("DRI::GenericFile")
  end

  # @return [Boolean]
  def object?
    !collection? && digital_object?
  end

  def collection?
    truthy_index_field?('is_collection_ssi')
  end

  def root_collection?
    # a collection without any governing / parent collection
    collection? && (collection_id ? false : true)
  end

  def sub_collection?
    collection? && !root_collection?
  end

  def institutes
    institute_names = ancestor_field(Solrizer.solr_name('institute', :stored_searchable, type: :string))
    institutes = Institute.where(name: institute_names)

    institutes.to_a
  end

  def licence
    licence_key = Solrizer.solr_name('licence', :stored_searchable, type: :string).to_sym
    if self[licence_key].present?
      Licence.where(name: self[licence_key]).first || self[licence_key]
    else
      retrieve_ancestor_licence
    end
  end

  def object_profile
    key = Solrizer.solr_name('object_profile', :displayable)

    self[key].present? ? JSON.parse(self[key].first) : {}
  end

  def root_collection_id
    root_key = 'root_collection_id_ssi'.to_sym

    self[root_key].present? ? self[root_key] : nil
  end

  def root_collection
    root_id = root_collection_id
    return self if root_id && ancestor_docs.blank?
    ancestor_docs[root_id] if root_id && ancestor_docs.key?(root_id)
  end

  def relatives
    relatives_key = Solrizer.solr_name('isMemberOf', :symbol)
    return [] unless self[relatives_key].present?

    self[relatives_key]
  end

  def governing_collection
    governing_id = collection_id
    return nil unless governing_id

    ancestor_docs[governing_id]
  end

  def retrieve_ancestor_licence
    ancestors_key = 'ancestor_id_ssim'.to_sym
    return nil unless ancestor_docs.present?

    licence_key = Solrizer.solr_name('licence', :stored_searchable, type: :string).to_sym

    ancestor_ids.each do |id|
      doc = ancestor_docs[id]
      return Licence.where(name: doc[licence_key]).take if doc[licence_key].present?
    end

    nil
  end

  def status
    self['status_ssi'.to_sym]
  end

  def draft?
    status == 'draft'
  end

  def published?
    ancestors_published? && status == 'published'
  end

  def public_read?
    read_access_groups_key = Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)
    groups = get_permission_key(self.id, read_access_groups_key)
    return false if groups.nil? #groups could be nil if read access set to restricted

    groups.include?(SETTING_GROUP_PUBLIC)
  end

  def permissions_doc(id)
    get_permissions_solr_response_for_doc_id(id)
  end
end
