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

    @audit_trail = @object.versions.all

    @datastreams = @object.attached_files.keys
    metadata_streams = @object.attached_files

    @metadata_versions = Hash.new

    @datastreams.each do |datastream|
      @metadata_versions[datastream] = { version: { created: @object.create_date, uri: @object.uri, committer: @object.depositor } }

      if metadata_streams[datastream].has_versions?
        versions = metadata_streams[datastream].versions.all

        versions.each do |v|
          @metadata_versions[datastream][v.label.to_sym] = { created: v.created, uri: v.uri, committer: committer(v) }
        end
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

