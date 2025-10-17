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

  ANCESTORS_KEY = 'ancestor_id_ssim'.to_sym
  COPYRIGHT_KEY = 'copyright_tesim'.freeze

  def self.find(id)
    Solr::Query.find(id)
  end

  def self.find_by_alternate_id(id)
    Solr::Query.find_by_alternate_id(id)
  end

  def self.delete(id)
    Valkyrie::MetadataAdapter.find(:index_solr).persister.connection.delete_by_id(id, params: { 'softCommit' => true })
  end

  def alternate_id
    self['alternate_id']
  end

  def active_fedora_model
    self['active_fedora_model_ssi']
  end

  def ancestor_docs
    @ancestor_docs ||= load_ancestors
  end

  def load_ancestors
    ids = ancestor_ids
    if ids.present?
      docs = {}
      query = Solr::Query.construct_query_for_ids(ids, 'alternate_id')
      results = Solr::Query.new(query, 100, { rows: ids.length }).to_a
      results.each { |r| docs[r['alternate_id']] = r }
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
    return [] unless self[ANCESTORS_KEY].present?

    self[ANCESTORS_KEY]
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
    return false if self['file_type_tesim'].blank?

    self['file_type_tesim'].include?('image')
  end

  def valid_edm?
    return false if self['file_type_tesim'].blank?
    
    (['3d','video','audio','text','image'] & self['file_type_tesim']).any?
  end
  
  def dataset?
    dataset = ancestor_field("dataset_ss")
    return true if dataset && dataset == "Research"
    
    false
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
    self['geojson_ssim'].present?
  end

  def has_aggregation_data?
    aggregation = Aggregation.find_by(collection_id: root_collection_id)
    return false unless aggregation

    aggregation.aggregation_id.present?
  end

  def identifier
    self['identifier_ssim']
  end

  def linkset?
    if object? && self['file_count_isi'].present? && published?
      true
    elsif collection? && published?
      true
    else
      false
    end
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
    institute_names = ancestor_field('institute_tesim')
    institutes = Institute.where(name: institute_names)

    institutes.to_a
  end

  def licence
    licence_key = 'licence_tesim'.freeze
    if self[licence_key].present?
      Licence.where(name: self[licence_key]).first || self[licence_key]
    else
      retrieve_ancestor_licence
    end
  end

  def copyright
    if self[COPYRIGHT_KEY].present?
      Copyright.where(name: self[COPYRIGHT_KEY]).first || self[COPYRIGHT_KEY]
    else
      retrieve_ancestor_copyright
    end
  end

  def find_metadata_matches
    q = Solr::Query.new(
      "metadata_checksum_ssi:#{self['metadata_checksum_ssi']}", 
      100, 
      { fq: ["-alternate_id:#{self.alternate_id}", "ancestor_id_ssim:#{self.collection_id}"] }
    )

    q.to_a
  end

  def object_profile
    key = 'object_profile_ssm'.freeze

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
    relatives_key = 'isMemberOf_ssim'.freeze
    return [] unless self[relatives_key].present?

    self[relatives_key]
  end

  def governing_collection
    governing_id = collection_id
    return nil unless governing_id

    ancestor_docs[governing_id]
  end

  def retrieve_ancestor_licence
    return nil unless ancestor_docs.present?

    licence_key = Solrizer.solr_name('licence', :stored_searchable, type: :string).to_sym

    ancestor_ids.each do |id|
      doc = ancestor_docs[id]
      return nil unless doc
      return Licence.where(name: doc[licence_key]).take if doc[licence_key].present?
    end

    nil
  end

  def retrieve_ancestor_copyright
    return nil unless ancestor_docs.present?

    ancestor_ids.each do |id|
      doc = ancestor_docs[id]
      return nil unless doc
      return Copyright.where(name: doc[COPYRIGHT_KEY]).take if doc[COPYRIGHT_KEY].present?
    end

    nil
  end

  def thumbnail
    return nil unless self.key?('thumbnail_ss') && self['thumbnail_ss'].present?

    self['thumbnail_ss']
  end

  def setspec
    ancestor_field('setspec_ssim')
  end

  def allow_aggregation?
    self.setspec.present?
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
    groups = ancestor_field('read_access_group_ssim')
    return false if groups.nil? #groups could be nil if read access set to restricted

    groups.include?(SETTING_GROUP_PUBLIC)
  end

  def visibility
    groups = ancestor_field('read_access_group_ssim')
    return "restricted" if groups.blank?

    return "public" if groups.include?(SETTING_GROUP_PUBLIC)
    return "logged-in" if groups.include?(SETTING_GROUP_DEFAULT)

    "restricted"
  end

  def permissions_doc(id)
    get_permissions_solr_response_for_doc_id(id)
  end
end
