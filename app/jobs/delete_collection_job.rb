class DeleteCollectionJob < IdBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.alternate_id}"

    solr_query = "ancestor_id_ssim:\"#{object.alternate_id}\""
    f_query = "is_collection_ssi:false"

    if object.status != "published"
      query = Solr::Query.new(solr_query, 1000, fq: f_query)
      query.each do |obj|
        child_object = DRI::DigitalObject.find_by_alternate_id(obj.id)
        if child_object.published?
          # update moab
          update_moab(child_object)
        else
          # cleanup filesystem
          cleanup_moab(child_object)
        end
      end

      preservation = Preservation::Preservator.new(object)
      preservation.remove_moab_dirs
    end

    object.destroy

    CollectionConfig.find_by(collection_id: object.alternate_id).destroy if CollectionConfig.exists?(collection_id: object.alternate_id)
  end

  def update_moab(child)
    # Do the preservation actions
    child.increment_version
    assets = []
    child.generic_files.map { |gf| assets << "#{gf.alternate_id}_#{gf.label}" }
    
    preservation = Preservation::Preservator.new(child)
    preservation.update_manifests(
      deleted: {
        'content' => assets,
        'metadata' => ['descMetadata.xml']
      }
    )
  end

  def cleanup_moab(child)
    preservation = Preservation::Preservator.new(child)
    preservation.remove_moab_dirs
  end
end
