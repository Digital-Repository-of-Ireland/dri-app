# frozen_string_literal: true
require 'moab'
require 'preservation/preservation_helpers'

class ObjectHistory
  include ActiveModel::Model
  include Preservation::PreservationHelpers

  attr_accessor :object

  # Get the institute manager for any collection or object
  def institute_manager
    object.root_collection['depositor_ss']
  end

  def audit_trail
    object_versions = moab_versions
    db_versions = version_committers
    object_versions.map do |version|
      trail = { version_id: version.version_name }

      if db_versions.key?(version.version_name)
        trail[:created] = db_versions[version.version_name][:created].iso8601
        trail[:committer] = db_versions[version.version_name][:committer]
      else
        trail[:created] = File::Stat.new(version.version_pathname).ctime.utc.iso8601
      end
      trail
    end
  end

  def fixity
    object.collection? ? fixity_check_collection : fixity_check_object
  end

  def fixity_check_collection
    fixity_check = { time: Time.now.to_s, verified: 'unknown', result: [] }
    return fixity_check unless FixityReport.exists?(collection_id: object.alternate_id)

    fixity_report = FixityReport.where(collection_id: object.alternate_id).latest

    fixity_check[:time] = fixity_report.created_at
    failures = fixity_report.fixity_checks.failed.to_a
    if failures.any?
      fixity_check[:verified] = 'failed'
      fixity_check[:result].push(*failures.to_a.map(&:object_id))
      fixity_check[:failures] = failures.length
    elsif fixity_check[:verified] == 'unknown'
      fixity_check[:verified] = 'passed'
    end

    fixity_check
  end

  def fixity_check_object
    fixity_check = {}

    return fixity_check unless FixityCheck.exists?(object_id: object.alternate_id)

    check = FixityCheck.where(object_id: object.alternate_id).last
    fixity_check[:time] = check.created_at
    fixity_check[:verified] = check.verified == true ? 'passed' : 'failed'
    fixity_check[:result] = check.result

    fixity_check
  end

  def moab_versions
    storage_object = Moab::StorageObject.new(object.alternate_id, aip_dir(object.alternate_id))
    storage_object.versions.map
  end

  def version_committers
    committed_versions = VersionCommitter.where(obj_id: object.alternate_id).order('created_at asc')
    version_hash = {}
    committed_versions.each do |version|
      version_hash[version.version_id] = {
        version_id: version.version_id,
        created: version.created_at,
        committer: version.committer_login
      }
    end
    version_hash
  end
end
