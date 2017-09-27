module DRI
  module Object
    class Actor
      attr_reader :object, :user

      def initialize(object, user)
        @object = object
        @user = user
      end

      def find_duplicates
        if @object.governing_collection.present?
          ActiveFedora::SolrService.query(
            solr_query,
            defType: 'edismax',
            rows: '10',
            fl: 'id'
          ).delete_if { |obj| obj['id'] == @object.noid }
        end
      end

      def solr_query
        md5_field = ActiveFedora.index_field_mapper.solr_name(
          'metadata_md5',
          :stored_searchable,
          type: :string
        )
        governed_field = ActiveFedora.index_field_mapper.solr_name(
          'isGovernedBy',
          :stored_searchable,
          type: :symbol
        )
        query = "#{md5_field}:\"#{@object.metadata_md5.first}\""
        query += " AND #{governed_field}:\"#{@object.governing_collection.noid}\""
        query
      end

      def version_and_record_committer
        version_id = @object.object_version

        VersionCommitter.create(version_id: version_id, obj_id: @object.noid, committer_login: @user.to_s)
      end
    end
  end
end
