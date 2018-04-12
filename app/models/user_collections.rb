class UserCollections
  include ActiveModel::Model

  attr_accessor :user
 
  def collections_data
    user.is_admin? ? admin_collections_data : user_collections_data
  end 

  private

    def admin_collections_data
      query = Solr::Query.new(
        "#{ActiveFedora.index_field_mapper.solr_name('depositor', :searchable, type: :symbol)}:#{user.email}",
        100,
        { fq: ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true",
              "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"] }
      )

      collections = collections(query)
      collections.map { |item| item[:permission] = 'Depositor' }
      
      collections
    end
    
    def user_collections_data
      query = "#{ActiveFedora.index_field_mapper.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{user.email} OR "\
        "#{ActiveFedora.index_field_mapper.solr_name('edit_access_person', :stored_searchable, type: :symbol)}:#{user.email}"

      read_query = read_group_query(user)
      query <<   " OR (" + read_query + ")" unless read_query.nil?

      solr_query = Solr::Query.new(
        query,
        100,
        { fq: ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true",
              "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"]}
      )

      collections(solr_query)
    end

    def collections(query)
      collections = []

      query.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object[
          ActiveFedora.index_field_mapper.solr_name(
          'title', :stored_searchable, type: :string
          )
        ]

        permissions = []
        {'manager' => 'manage', 'edit' => 'edit'}.each do |permission, label|
          type = permission_type(user, object, permission, label)
          permissions << type if type
        end
        
        permissions << 'read' if user.groups.pluck(:name).include?(object['id'])

        collection[:permission] = permissions.join(', ') if permissions
        collections.push(collection)
      end

      collections
    end

    def read_group_query(user)
      group_query_fragments = user.groups.map do |group|
        "#{ActiveFedora.index_field_mapper.solr_name(
          'read_access_group', :stored_searchable, type: :symbol)}:#{group.name}" unless group.name == "registered"
      end
      return nil if group_query_fragments.compact.blank?
      group_query_fragments.compact.join(" OR ")
    end

    def permission_type(user, object, role, label)
      key = ActiveFedora.index_field_mapper.solr_name("#{role}_access_person", :stored_searchable, type: :symbol)
      label if object[key].present? && object[key].include?(user.email)
    end
end
