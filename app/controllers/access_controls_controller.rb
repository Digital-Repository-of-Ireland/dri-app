class AccessControlsController < ApplicationController
  before_action :read_only, except: :edit
  before_action ->(id=params[:id]) { locked(id) }, except: :edit

  include DRI::Versionable

  def edit
    enforce_permissions!('edit', params[:id])
    @object = retrieve_object!(params[:id])

    respond_to do |format|
      format.js
    end
  end

  def update
    @object = retrieve_object!(params[:id])
    @object.collection? ? enforce_permissions!('manage_collection', params[:id]) : enforce_permissions!('edit', params[:id])

    params[:batch][:read_users_string] = params[:batch][:read_users_string].to_s.downcase
    params[:batch][:edit_users_string] = params[:batch][:edit_users_string].to_s.downcase
    params[:batch][:manager_users_string] = params[:batch][:manager_users_string].to_s.downcase if params[:batch][:manager_users_string].present?

    version = @object.object_version || '1'
    params[:batch][:object_version] = version.next

    permissionchange = permissions_changed?
    updated = @object.update_attributes(update_params) unless @object.collection? && !valid_permissions?

    if updated
      flash[:notice] = t('dri.flash.notice.access_controls_updated')

      record_version_committer(@object, current_user)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(@object)
      preservation.preserve(false, permissionchange, ['properties'])
    else
      flash[:alert] = t('dri.flash.error.not_updated', item: params[:id])
    end

    #purge params from update action
    purge_params

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: @object.id }
    end
  end

  def show
    enforce_permissions!('edit', params[:id])
    @collection = SolrDocument.find(params[:id])
    @collection_id = @collection.id
    @title = @collection['title_tesim'].first

    collections = [@collection].concat(@collection.descendants)

    respond_to do |format|
      format.html { @access_controls = nested_hash(build_access_controls_tree_entries(collections))
}
      format.csv { send_data to_csv(collections), filename: "#{@title.parameterize}-access-controls-#{Date.today}.csv" }
    end
  end

  private

    def build_access_controls_tree_entries(collections)
      entries = []
      collections.each do |document|
        id = document.id
        permissions = read_permissions(document)

        title = "#{document['title_tesim'].first}: #{permissions[:read_label]} #{permissions[:assets_label]}"
        parents = document['ancestor_id_tesim']
        inherit_objects = count_objects_with_inherited_permissions(document)

        entries << {
                     id: id,
                     type: 'folder',
                     name: title,
                     dataAttributes: {
                                      'data-read' => permissions[:read_access],
                                      'data-assets' => permissions[:assets]
                                    },
                     parent_id: parents.nil? ? nil : parents.first
                   }

        # objects that inherit the permissions
        if inherit_objects > 0
          entries << {
                       id: "#{id}-inherit",
                       type: 'item',
                       name: t('dri.views.objects.access_controls.inherit_objects', count: inherit_objects),
                       attr: {
                        "data-icon": "glyphicon glyphicon-info-sign"
                       },
                       parent_id: document.id
                     }
        end

        # add list of objects that have custom settings
        objects = objects_with_permissions(document)
        if objects.size > 0
          entries << {
                       id: "#{id}-custom",
                       type: 'folder',
                       name: t('dri.views.objects.access_controls.custom_objects', count: objects.size),
                       attr: {
                        "data-icon": "glyphicon glyphicon-info-sign"
                       },
                       parent_id: id
                     }
        end

        objects.each do |object|
          object_permissions = read_permissions(object)
          entries << {
                       id: "#{object.id}",
                       type: 'item',
                       name: "#{object['title_tesim'].first}: #{object_permissions[:read_label]} #{object_permissions[:assets_label]}",
                       attr: {
                        "data-icon": "glyphicon glyphicon-file"
                       },
                       dataAttributes: {
                                      'data-read' => object_permissions[:read_access],
                                      'data-assets' => object_permissions[:assets]
                                    },
                       parent_id: "#{id}-custom"
                     }
        end
      end

      entries
    end

    def nested_hash(entries)
      nested_hash = Hash[entries.map { |e| [e[:id], e.merge(children: [])] }]
      nested_hash.each do |_id, item|
        parent = nested_hash[item[:parent_id]]
        parent[:children] << item if parent
      end
      nested_hash.select { |_id, item| item[:parent_id].nil? }.values
    end

    def count_objects_with_inherited_permissions(collection)
      ActiveFedora::SolrService.count(
                                 "collection_id_sim:#{collection['id']}",
                                 fq: ['is_collection_sim:false',
                                     '-read_access_group_ssim:[* TO *]',
                                     '-(-master_file_access_sim:inherit master_file_access_sim:*)'
                                 ]
                               )
    end

    def objects_with_inherited_permissions(collection)
      query = ::Solr::Query.new(
                                 "collection_id_sim:#{collection['id']}",
                                 100,
                                 fq: ['is_collection_sim:false',
                                     '-read_access_group_ssim:[* TO *]',
                                     '-(-master_file_access_sim:inherit master_file_access_sim:*)'
                                 ]
                               )
      query.to_a
    end

    def objects_with_permissions(collection)
      query = ::Solr::Query.new("collection_id_sim:#{collection['id']}",
                                100,
                                fq: ['is_collection_sim:false',
                                     'read_access_group_ssim:[* TO *]',
                                     '-master_file_access_sim:inherit',
                                     'master_file_access_sim:[* TO *]']
                                )
      query.to_a
    end

    def read_permissions(object)
      permissions = {}
      read_groups = object.ancestor_field('read_access_group_ssim')

      case read_groups
      when ['registered']
        permissions[:read_access] = 'logged-in'
        permissions[:read_label] = t("dri.views.objects.access_controls.report.logged_in")
      when ['public']
        permissions[:read_access] = 'public'
        permissions[:read_label] = t("dri.views.objects.access_controls.report.public")
      else
        permissions[:read_access] = 'approved'
        permissions[:read_label] = t("dri.views.objects.access_controls.report.restricted")
      end

      read_master = object.read_master? ? 'public' : 'private'
      permissions[:assets] = read_master
      permissions[:assets_label] = t("dri.views.objects.access_controls.inherit_strings.#{read_master}")

      permissions
    end

    def to_csv(collections)
      headers = ['collection', 'title', 'users', 'asset file access']
      CSV.generate(headers: true) do |csv|
        csv << headers

        collections.each do |collection|
          inherit_objects = objects_with_inherited_permissions(collection)
          objects = objects_with_permissions(collection)
          inherit_objects.concat(objects).each do |object|
            permissions = read_permissions(object)
            csv << [
                     collection['title_tesim'].first,
                     object['title_tesim'].first,
                     permissions[:read_access],
                     permissions[:assets_label]
                   ]
          end
        end
      end
    end

    def purge_params
      params.delete(:batch)
      params.delete(:_method)
      params.delete(:authenticity_token)
      params.delete(:commit)
      params.delete(:action)
    end

    def update_params
      params.require(:batch).permit(
        :read_groups_string,
        :read_users_string,
        :master_file_access,
        :edit_groups_string,
        :edit_users_string,
        :manager_users_string,
        :object_version
      )
    end

    def valid_permissions?
      !(
        @object.governing_collection_id.blank? &&
        (params[:batch][:manager_users_string].blank? && params[:batch][:edit_users_string].blank?)
      )
    end

    def permissions_changed?
      !(@object.read_groups_string == params[:batch][:read_groups_string] &&
      @object.edit_users_string == params[:batch][:edit_users_string] &&
      @object.manager_users_string == params[:batch][:manager_users_string])
    end

end
