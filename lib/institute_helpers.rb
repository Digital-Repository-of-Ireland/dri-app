module InstituteHelpers


  # get the institues for this collection
  def self.get_collection_institutes(collection)
    allinstitutes = Institute.find(:all)
    myinstitutes = []
    allinstitutes.each do |inst|
      if collection.institute.include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end


  def self.get_object_institutes_from_solr_doc(doc)
    allinstitutes = Institute.find(:all)
    myinstitutes = []
    id = doc['is_governed_by_ssim'][0].gsub(/^info:fedora\//, '')
    solr_query = "id:#{id}"
    collection = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "1", :fl => "id,institute_tesim")
    allinstitutes.each do |inst|
      if collection[0]['institute_tesim'].include?(inst.name)
        myinstitutes.push(inst)
      end
    end
    return myinstitutes
  end

end
