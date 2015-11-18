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
    
    def version_and_record_committer
      VersionCommitter.create(obj_id: @object.id, committer_login: @user.to_s)
    end

  end
end
