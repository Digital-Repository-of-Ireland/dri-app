require 'moab'
require 'preservation/preservation_helpers'

class ObjectHistory
  include ActiveModel::Model
  include PreservationHelpers

  attr_accessor :object

  # Get the earliest ancestor for any inherited attribute
  def governing_attribute(attribute, parent = nil)
    current_object = parent || object
    begin
      value = current_object.send(attribute)
      return value if value.present?
      return nil if current_object.governing_collection.nil?
    rescue NoMethodError
      return nil
    end
    governing_attribute(attribute, current_object.governing_collection)
  end

  # Get the institute manager for any collection or object
  def institute_manager
    root_collection = DRI::Identifier.retrieve_object(object.root_collection.first)
    root_collection.try(:depositor).try(:first)
  end

  def read_users_by_group(parent = nil)
    current_object = parent || object
    users = []
    if current_object.read_groups.present?
      current_object.read_groups.each do |group_name|
        next if %w(public registered).include?(group_name)

        group = UserGroup::Group.where(name: group_name)
        group.first.users.each do |user|
          users << [user.first_name, user.second_name, user.email]
        end
      end

      users
    elsif current_object.governing_collection.nil?
      []
    else
      read_users_by_group(current_object.governing_collection)
    end
  end

  def audit_trail
    versions = {}

    if has_versions?
      audit_trail = object_versions
      audit_trail.each { |version| versions[version.version_name] = version_info(version.version_id) }
    end

    versions
  end

  def asset_info
    asset_info = {}

    object.generic_files.each do |file|
      asset_info[file.noid] = {}
      asset_info[file.noid][:surrogates] = surrogate_info(file.noid)
    end

    asset_info
  end

  def version_info(version)
    vc = VersionCommitter.where(version_id: version, obj_id: object.noid).take
    { created: vc.created_at, committer: vc.committer_login }
  end

  def has_versions?
    object_versions.count > 0
  end

  def object_versions
    storage_object = Moab::StorageObject.new(object.noid, base_path(object.noid))
    storage_object.versions
  end

  def licence
    governing_attribute('licence')
  end

  def permission_info
    {
      institute_manager: institute_manager,
      read_groups: governing_attribute('read_groups_string'),
      read_users: read_users_by_group,
      edit_users: governing_attribute('edit_users_string'),
      manager_users: governing_attribute('manager_users_string')
    }
  end

  def surrogate_info(file_id)
    storage = StorageService.new
    surrogates = storage.surrogate_info(@object.noid, file_id)

    surrogates
  end
end
