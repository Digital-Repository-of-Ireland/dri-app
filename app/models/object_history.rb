require 'moab'
require 'preservation/preservation_helpers'

class ObjectHistory
  include ActiveModel::Model
  include Preservation::PreservationHelpers

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
    parent = object.governing_collection
    return object.try(:depositor) if parent.nil?

    while !parent.nil?
      current = parent
      parent = current.governing_collection
    end

    current.try(:depositor)
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
    versions = []

    committed_versions = VersionCommitter.where(obj_id: object.noid).order('created_at asc')
    committed_versions.each do |version|
      versions << { version_id: version.version_id,
                    created: version.created_at,
                    committer: version.committer_login
                  }
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

  def fixity
    object.collection? ? fixity_check_collection : fixity_check_object
  end

  def fixity_check_collection
    fixity_check = {}
    fixity_check[:time] = Time.now.to_s
    fixity_check[:verified] = 'unknown'
    fixity_check[:result] = []

    return fixity_check unless FixityCheck.exists?(collection_id: object.noid)

    fixity_check[:time] = FixityCheck.where(collection_id: object.noid).latest.first.created_at
    failures = FixityCheck.where(collection_id: object.noid).failed.to_a
    if failures.any?
      fixity_check[:verified] = 'failed'
      fixity_check[:result].push(*failures.to_a.map(&:object_id))
    else
      fixity_check[:verified] = 'passed' if fixity_check[:verified] == 'unknown'
    end

    fixity_check
  end

  def fixity_check_object
    fixity_check = {}

    return fixity_check unless FixityCheck.exists?(object_id: object.noid)

    check = FixityCheck.where(object_id: object.noid).last
    fixity_check[:time] = check.created_at
    fixity_check[:verified] = check.verified == true ? 'passed' : 'failed'
    fixity_check[:result] = check.result

    fixity_check
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
    surrogates = storage.surrogate_info(object.noid, file_id)

    surrogates
  end
end
