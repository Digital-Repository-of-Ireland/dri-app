class UserCollections
  include ActiveModel::Model

  attr_accessor :user

  def collections_data
    user.is_admin? ? admin_collections_data : user_collections_data
  end

  def collections_count
    user.is_admin? ? count(:admin) : count(:user)
  end

  private

    def count(user_type)
      query = if user_type == :admin
                admin_query
              else
                user_query
              end

      ActiveFedora::SolrService.count(query, fq: root_collection_filter)
    end

    def admin_collections_data
      query = Solr::Query.new(
        admin_query,
        100,
        { fq: root_collection_filter }
      )

      collections = collections(query)
      collections.map { |item| item[:permission] = 'Depositor' }

      collections
    end

    def admin_query
      "depositor_sim:#{user.email}"
    end

    def user_collections_data
      solr_query = Solr::Query.new(
        user_query,
        100,
        { fq: root_collection_filter }
      )

      collections(solr_query)
    end

    def user_query
      query = "#{Solr::SchemaFields.searchable_symbol('manager_access_person')}:#{user.email} OR "\
        "#{Solr::SchemaFields.searchable_symbol('edit_access_person')}:#{user.email}"

      read_query = read_group_query(user)
      query <<   " OR (" + read_query + ")" unless read_query.nil?

      query
    end

    def collections(query)
      collections = []

      query.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object['title_tesim']

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
        "#{Solr::SchemaFields.searchable_symbol(
          'read_access_group')}:#{group.name}" unless group.name == "registered"
      end
      return nil if group_query_fragments.compact.blank?
      group_query_fragments.compact.join(" OR ")
    end

    def root_collection_filter
      [
        "+is_collection_sim:true",
        "-ancestor_id_sim:[* TO *]"
      ]
    end

    def permission_type(user, object, role, label)
      key = Solr::SchemaFields.searchable_symbol("#{role}_access_person")
      label if object[key].present? && object[key].include?(user.email)
    end
end
