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

    @audit_trail = @object.versions

    @records = Hash.new
    #@audit_trail.each do |record|
    #  @records[record.uri] ||= Hash.new
    #  @records[record.uri][record.created] = record.
    #end

    #@datastreams = @records.keys
    #@fedora_url = "#{ActiveFedora.config.credentials[:url]}/objects/#{@object.id}/datastreams"

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

end

