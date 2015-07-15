# -*- encoding : utf-8 -*-
# Generated Solr Document model
#
class SolrDocument 
 
  include Blacklight::Document
  include UserGroup::PermissionsSolrDocOverride
  include FileDocument

  # self.unique_key = 'id'
  
  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )

  def active_fedora_model
    self[ActiveFedora::SolrQueryBuilder.solr_name('active_fedora_model', :stored_sortable, type: :string)]
  end

  def collection_id
    collection_key = ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)

    self[collection_key].present? ? self[collection_key][0] : nil
  end  

  def editable?
    (self.active_fedora_model && self.active_fedora_model == 'DRI::EncodedArchivalDescription') ? false : true
  end

  def has_doi?
    doi_key = ActiveFedora::SolrQueryBuilder.solr_name('doi', :displayable, type: :symbol).to_sym

    self[doi_key].present? ? true : false
  end

  def has_geocode?
    geojson_key = ActiveFedora::SolrQueryBuilder.solr_name('geojson', :stored_searchable, type: :symbol).to_sym

    self[geojson_key].present? ? true : false
  end

  def root_collection
    root_key = ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym
    root = nil
    if self[root_key].present?
      id = self[root_key][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1")
      root = collection[0]
    end
    
    root
  end

  def is_root_collection?
    self.collection_id ? true : false  
  end

  def status
    status_key = ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :string).to_sym

    return self[status_key].first
  end

  def published?
    self.status == "published"
  end

  def draft?
    self.status == "draft"
  end

end
