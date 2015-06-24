module DOI

  def self.mint_doi( object )
    unless DoiConfig.nil?
      if object.status.eql?("published")
        doi = DataciteDoi.create(object_id: object.id) 

        begin
          Sufia.queue.push(MintDoiJob.new(object.id))
	rescue Exception => e
          Rails.logger.error "Unable to mint DOI: #{e.message}"
        end
      end
    end
  end    

  def self.update_doi( object, modified, mod_version )
    unless DoiConfig.nil?
      if object.status.eql?("published")
        current = DataciteDoi.where(object_id: object_id).current
        doi = DataciteDoi.create(object_id: object.id, version: (current.version + 1), modified: modified, mod_version: mod_version)

        begin
          Sufia.queue.push(MintDoiJob.new(object.id))
        rescue Exception => e
          Rails.logger.error "Unable to mint DOI: #{e.message}"
        end
      end
    end
  end
    
  end

end
