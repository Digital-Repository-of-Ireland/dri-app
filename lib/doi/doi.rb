module DOI

  def self.mint_doi( object )
    unless DoiConfig.nil?
      if object.status.eql?("published") && object.doi.nil?
        begin
          Sufia.queue.push(MintDoiJob.new(object.id))
	rescue Exception => e
          logger.error "Unable to mint DOI: #{e.message}"
        end
      end
    end
  end    

end
