module DOI

  def self.mint_doi( doi )
    unless DoiConfig.nil?
      if object.status.eql?("published") && object.doi.nil?
        begin
          Sufia.queue.push(MintDoiJob.new(doi.object_id))
	rescue Exception => e
          Rails.logger.error "Unable to mint DOI: #{e.message}"
        end
      end
    end
  end    

end
