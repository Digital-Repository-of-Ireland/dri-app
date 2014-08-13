# Controller for generating a per-object history/audit report
#


class ObjectHistoryController < ApplicationController

  before_filter :authenticate_user_from_token!, :only => [:show]
  before_filter :authenticate_user!, :only => [:show]

  def show
    # TODO: determine what the permissions should be
    # should read users be able to see any object history
    # e.g. researchers looking for provenance?
    enforce_permissions!("edit", params[:id])

    @object = retrieve_object!(params[:id])

    @audit_trail = @object.audit_trail

    @records = Hash.new
    @object.audit_trail.records.each do |record|
      @records[record.component_id] ||= Hash.new
      @records[record.component_id][record.date] = record.action
    end

    @datastreams = @records.keys

    respond_to do |format|
      format.html
    end
  end

end

