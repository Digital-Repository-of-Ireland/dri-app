class Hydra::PermissionsSolrDocument < SolrDocument
  def under_embargo?
    #permissions = permissions_doc(params[:id])
    embargo_key = ActiveFedora::SolrService.solr_name("embargo_release_date", Hydra::Datastream::RightsMetadata.date_indexer)
    if self[embargo_key] 
      embargo_date = Date.parse(self[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end

  def is_public?
    key = ActiveFedora::SolrService.solr_name("access", Hydra::Datastream::RightsMetadata.indexer)
    self[key].present? && self[key].first.downcase == "public"
  end

  def is_private?
    key = ActiveFedora::SolrService.solr_name('private_metadata', Hydra::Datastream::RightsMetadata.integer_indexer).to_s
    if self[key].present?
      return true if self[key].to_s == "1"
      return false if self[key].to_s == "0"
    end
    return nil
  end

  def show_master_file?
    key = ActiveFedora::SolrService.solr_name('master_file', Hydra::Datastream::RightsMetadata.integer_indexer).to_s
    if self[key].present?
      return true if self[key].to_s == "1"
      return false if self[key].to_s == "0"
    end
    return nil
  end

  def is_published?
    #TODO:: finish
    key = "properties_status_ssm" #ActiveFedora::SolrService.solr_name('properties_status', Hydra::Datastream::RightsMetadata).to_s
    self[key].present? && self[key].first.downcase == "published"
  end
  

end