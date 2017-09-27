# Controller for generating a per-object history/audit report
#
class ObjectHistoryController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def show
    # TODO: determine what the permissions should be
    # should read users be able to see any object history
    # e.g. researchers looking for provenance?
    enforce_permissions!('edit', params[:id])

    @object = retrieve_object!(params[:id])

    object_history = ObjectHistory.new(object: @object)

    @versions = object_history.audit_trail
    @asset_info = object_history.asset_info
    @permission_info = object_history.permission_info

    @licence = object_history.licence

    respond_to do |format|
      format.html
    end
  end
end
