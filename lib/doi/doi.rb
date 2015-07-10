module DOI

  def self.mint_doi( doi )
    if DoiConfig
      if object.status == "published" && object.doi.nil?
        doi = DataciteDoi.create(object_id: object.id) 

        begin
          Sufia.queue.push(MintDoiJob.new(doi.object_id))
	rescue Exception => e
          Rails.logger.error "Unable to mint DOI: #{e.message}"
        end
      end
    end
  end    

  def self.update_doi( object, modified, mod_version )
    if DoiConfig
      if object.status == "published"
        doi = DataciteDoi.create(object_id: object.id, modified: modified, mod_version: mod_version)

        begin
          Sufia.queue.push(MintDoiJob.new(object.id))
        rescue Exception => e
          Rails.logger.error "Unable to mint DOI: #{e.message}"
        end
      end
    end
  end
    
end

