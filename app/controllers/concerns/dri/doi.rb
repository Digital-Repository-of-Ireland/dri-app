module DRI::Doi
  extend ActiveSupport::Concern

    def update_doi(object, doi, modified)
        return if Settings.doi.enable != true || DoiConfig.nil?

        if (doi.changed? && object.status == "published")
          doi.mandatory_update? ? mint_doi(object, modified) : doi_metadata_update(object)
          doi.clear_changed
        end
      end

      def mint_doi(object, modified)
        return if Settings.doi.enable != true || DoiConfig.nil?

        if object.descMetadata.has_versions?
          DataciteDoi.create(object_id: object.id, modified: modified, mod_version: object.descMetadata.versions.last.uri)
        else
          DataciteDoi.create(object_id: object.id, modified: modified)
        end

        Sufia.queue.push(MintDoiJob.new(object.id))
      end

      def doi_metadata_update(object)
        Sufia.queue.push(UpdateDoiJob.new(object.id))
      end
    
end
