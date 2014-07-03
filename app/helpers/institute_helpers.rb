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


  def self.get_institutes_from_solr_doc(doc)
    doc[Solrizer.solr_name('object_type', :displayable, type: :string)][0] == 'Collection' ? self.get_collection_institutes_from_solr_doc(doc) : self.get_object_institutes_from_solr_doc(doc)
  end


  def self.get_object_institutes_from_solr_doc(doc)
    allinstitutes = Institute.all
    myinstitutes = []
    id = doc[Solrizer.solr_name('is_governed_by', :stored_searchable, type: :symbol)][0].gsub(/^info:fedora\//, '')
    solr_query = "id:#{id}"
    collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,#{Solrizer.solr_name('institute', :stored_searchable, type: :string)}")
    return nil if collection[0][Solrizer.solr_name('institute', :stored_searchable, type: :string)].blank?
    allinstitutes.each do |inst|
      if collection[0][Solrizer.solr_name('institute', :stored_searchable, type: :string)].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

  def self.get_collection_institutes_from_solr_doc(doc)
    return nil if doc[Solrizer.solr_name('institute', :stored_searchable, type: :string)].blank?
    allinstitutes = Institute.all
    myinstitutes = []
    allinstitutes.each do |inst|
      if doc[Solrizer.solr_name('institute', :stored_searchable, type: :string)].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

  def self.get_all_institutes
    return Institute.all
  end
end
