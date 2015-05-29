# Controller for generating a per-object history/audit report
#
require 'inheritance_methods'

class ObjectHistoryController < ApplicationController
  include InheritanceMethods

  before_filter :authenticate_user_from_token!, :only => [:show]
  before_filter :authenticate_user!, :only => [:show]

  def show
    # TODO: determine what the permissions should be
    # should read users be able to see any object history
    # e.g. researchers looking for provenance?
    enforce_permissions!("edit", params[:id])

    @object = retrieve_object!(params[:id])
    @fedora_url = @object.uri

    @file_versions = {}

    @object.attached_files.keys.each do |file_key|
      file = @object.attached_files[file_key]
      if file.has_versions?
        @audit_trail = file.versions.all

        @versions = {}
        @audit_trail.each do |version|
          @versions[version.label] = { uri: version.uri, created: version.created, committer: committer(version) }
        end 
     
        @file_versions[file_key] = @versions
      end
    end  

    # Get inherited values
    @institute_manager = get_institute_manager(@object)
    @read_groups = get_governing_attribute(@object, 'read_groups_string')
    @read_users = get_read_users_via_group(@object)
    @edit_users = get_governing_attribute(@object, 'edit_users_string')
    @manager_users = get_governing_attribute(@object, 'manager_users_string')
    @licence = get_governing_attribute(@object, 'licence')

    respond_to do |format|
      format.html
    end
  end

  private
  
    def committer version
      vc = VersionCommitter.where(version_id: version.uri)
      return vc.empty? ? nil : vc.first.committer_login
    end

end

