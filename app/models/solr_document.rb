# -*- encoding : utf-8 -*-
# Generated Solr Document model
#
class SolrDocument 
 
  include Blacklight::Solr::Document
  include UserGroup::PermissionsSolrDocOverride
  include FileDocument

  # self.unique_key = 'id'
  
  # The following shows how to setup this blacklight document to display marc documents
  #extension_parameters[:marc_source_field] = :marc_display
  #extension_parameters[:marc_format_type] = :marcxml
  #use_extension( Blacklight::Solr::Document::Marc) do |document|
  #  document.key?( :marc_display  )
  #end
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )

  def collection_id
    id = nil
    if self[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)]
      id = self[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)][0]
    end

    id
  end  

  def has_geocode?
    geojson_key = ActiveFedora::SolrQueryBuilder.solr_name('geojson', :stored_searchable, type: :symbol).to_sym

    if self[geojson_key].present?
      true
    else
      false
    end
  end

  def read_master?
    master_file_key = ActiveFedora::SolrQueryBuilder.solr_name('master_file_access', :stored_searchable, type: :string)

    governing_object = self

    while governing_object[master_file_key].nil? || governing_object[master_file_key] == "inherit"
      parent_id = governing_object[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)]
      return false if parent_id.nil?
      
      parent_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([parent_id.first])
    
      parent = ActiveFedora::SolrService.query(parent_query)
      governing_object = SolrDocument.new(parent.first)      
    end

    governing_object[master_file_key] == ["public"]
  end

  def status
    status_key = ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :string).to_sym

    return self[status_key]
  end

end
