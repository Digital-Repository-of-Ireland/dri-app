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


  def self.get_object_institutes

  end

end
