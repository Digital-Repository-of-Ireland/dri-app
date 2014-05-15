module InstituteHelpers


  # get the institues for this collection
  def self.get_collection_institutes(collection)
    return nil if collection.institute.blank?
    allinstitutes = Institute.find(:all)
    myinstitutes = []
    allinstitutes.each do |inst|
      if collection.institute.include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end


  def self.get_institutes_from_solr_doc(doc)
    doc['object_type_ssm'][0] == 'Collection' ? self.get_collection_institutes_from_solr_doc(doc) : self.get_object_institutes_from_solr_doc(doc)
  end


  def self.get_object_institutes_from_solr_doc(doc)
    allinstitutes = Institute.find(:all)
    myinstitutes = []
    id = doc['is_governed_by_ssim'][0].gsub(/^info:fedora\//, '')
    solr_query = "id:#{id}"
    collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,institute_tesim")
    return nil if collection[0]['institute_tesim'].blank?
    allinstitutes.each do |inst|
      if collection[0]['institute_tesim'].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

  def self.get_collection_institutes_from_solr_doc(doc)
    return nil if doc['institute_tesim'].blank?
    allinstitutes = Institute.find(:all)
    myinstitutes = []
    allinstitutes.each do |inst|
      if doc['institute_tesim'].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

  def self.get_all_institutes
    return Institute.all
  end
end
