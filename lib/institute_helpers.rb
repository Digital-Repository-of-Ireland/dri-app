module InstituteHelpers


  # get the institues for this collection
  def self.get_collection_institutes(collection)
    return nil if collection.institute.blank?
    allinstitutes = Institute.all
    myinstitutes = []
    allinstitutes.each do |inst|
      if collection.institute.include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end


  def self.get_depositing_institute(collection)
    return nil if collection.depositing_institute.blank?
    Institute.where(:name => collection.depositing_institute).first
  end

  def self.get_institutes_from_solr_doc(doc)
    doc[ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string)].include?('Collection') ? self.get_collection_institutes_from_solr_doc(doc) : self.get_object_institutes_from_solr_doc(doc)
  end


  def self.get_depositing_institute_from_solr_doc(doc)
    doc[ActiveFedora::SolrQueryBuilder.solr_name('type', :stored_searchable, type: :string)].include?('Collection') ? self.get_collection_depositing_institute_from_solr_doc(doc) : self.get_object_depositing_institute_from_solr_doc(doc)
  end


  def self.get_collection_depositing_institute_from_solr_doc(doc)
    if doc[ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :displayable, type: :string)].present?
      return Institute.where(:name => doc[ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :displayable, type: :string)]).first
    else
      return nil
    end
  end


  def self.get_object_depositing_institute_from_solr_doc(doc)
    if doc[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)]
      id = doc[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,#{ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :displayable, type: :string)}").first
      if collection[ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :displayable, type: :string)].present?
        return Institute.where(:name => collection[ActiveFedora::SolrQueryBuilder.solr_name('depositing_institute', :displayable, type: :string)]).first
      else
        return nil
      end
    else
      return nil
    end
  end

  def self.get_object_institutes_from_solr_doc(doc, depositing=nil)
    allinstitutes = Institute.all
    myinstitutes = []
    if doc[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)]
      # This query won't return the institute from the parent collection for those objects part of sub-collections
      id = doc[ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,#{ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)}")
      # FIX for inheriting the Institute from the root collection when the object is part of a subcollection
      if collection[0][ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)].blank?
        # Getting the Institute from the root collection
        id = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)][0]
        solr_query = "id:#{id}"
        collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,#{ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)}")
      end
    else
      # Getting the Institute from the root collection
      id = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,#{ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)}")
    end

    return nil if collection[0][ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)].blank?
    allinstitutes.each do |inst|
      if collection[0][ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

  def self.get_collection_institutes_from_solr_doc(doc)
    if doc[Solrizer.solr_name('institute', :stored_searchable, type: :string)].blank?
      # For collections from XML bulk ingest: getting the Institute from the root collection
      id = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,#{ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)}")
      return nil if collection[0][ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)].blank?
    else
      # Institute info present in the document
      collection = [doc]
    end

    allinstitutes = Institute.all
    myinstitutes = []
    allinstitutes.each do |inst|
      if collection[0][ActiveFedora::SolrQueryBuilder.solr_name('institute', :stored_searchable, type: :string)].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

  def self.get_all_institutes
    return Institute.all
  end
end
