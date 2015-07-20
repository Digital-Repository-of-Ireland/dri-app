module DRI::Object

  class Actor

    attr_reader :object, :user

    def initialize(object, user)
      @object = object
      @user = user
    end

    def find_duplicates
      if @object.governing_collection.present?
        collection_id = @object.governing_collection.id
        solr_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('metadata_md5', :stored_searchable, type: :string)}:\"#{@object.metadata_md5}\" AND #{ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :stored_searchable, type: :symbol)}:\"#{collection_id}\""
        ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "10", :fl => "id").delete_if{|obj| obj["id"] == @object.id}
      end
    end

    def mint_doi(modified)
      doi = DataciteDoi.where(object_id: @object.id).current
      
      if (@object.status == "published" && (doi.is_a?(DataciteDoi)))
        if @object.descMetadata.has_versions?
          DataciteDoi.create(object_id: @object.id, modified: modified, mod_version: @object.descMetadata.versions.last.uri)
        else
          DataciteDoi.create(object_id: @object.id, modified: modified)
        end

        Sufia.queue.push(MintDoiJob.new(@object.id))
      end
    end

    def version_and_record_committer
      #TODO Investigate reverting back to full object versioning
      #@object.create_version
      #VersionCommitter.create(version_id: @object.versions.last.uri, committer_login: @user.to_s)

      # For now, just versioning updates to descMetadata and properties datastreams
      if @object.attached_files.key?(:descMetadata)
        @object.descMetadata.create_version
        VersionCommitter.create(version_id: @object.descMetadata.versions.last.uri, committer_login: @user.to_s)
      end
      if @object.attached_files.key?(:properties)
        @object.properties.create_version
        VersionCommitter.create(version_id: @object.properties.versions.last.uri, committer_login: @user.to_s)
      end
    end

  end
end
