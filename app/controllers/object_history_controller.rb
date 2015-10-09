# Controller for generating a per-object history/audit report
#
require 'inheritance_methods'

class ObjectHistoryController < ApplicationController
  include InheritanceMethods

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!

  def show
    # TODO: determine what the permissions should be
    # should read users be able to see any object history
    # e.g. researchers looking for provenance?
    enforce_permissions!('edit', params[:id])

    @object = retrieve_object!(params[:id])
    @fedora_url = @object.uri.to_str

    audit_trail
    asset_info
    permission_info

    @licence = get_governing_attribute(@object, 'licence')

    respond_to do |format|
      format.html
    end
  end

  private

  def audit_trail
    @file_versions = {}

    @object.attached_files.keys.each do |file_key|
      file = @object.attached_files[file_key]
      next unless file.has_versions?

      @audit_trail = file.versions.all
      @versions = {}
      @audit_trail.each do |version|
        @versions[version.label] = { uri: version.uri, created: version.created, committer: committer(version) }
      end

      @file_versions[file_key] = @versions
    end
  end

  def asset_info
    @asset_info = {}

    @object.generic_files.each do |file|
      @asset_info[file.id] = {}

      @asset_info[file.id][:versions] = local_files(file.id)
      @asset_info[file.id][:surrogates] = surrogate_info(file.id)
    end
  end

  def committer(version)
    vc = VersionCommitter.where(version_id: version.uri)
    vc.empty? ? nil : vc.first.committer_login
  end

  def local_files(file_id)
    LocalFile.where('fedora_id LIKE :f AND ds_id LIKE :d', { f: file_id, d: 'content' }).to_a
  end

  def permission_info
    @institute_manager = get_institute_manager(@object)
    @read_groups = get_governing_attribute(@object, 'read_groups_string')
    @read_users = get_read_users_via_group(@object)
    @edit_users = get_governing_attribute(@object, 'edit_users_string')
    @manager_users = get_governing_attribute(@object, 'manager_users_string')
  end

  def surrogate_info(file_id)
    storage = Storage::S3Interface.new
    surrogates = storage.get_surrogate_info @object.id, file_id

    surrogates
  end
end

