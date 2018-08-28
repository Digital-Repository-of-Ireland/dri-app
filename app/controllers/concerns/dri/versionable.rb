module DRI
  module Versionable
    extend ActiveSupport::Concern

    def version_and_record_committer(object, user)
      object.create_version

      VersionCommitter.create(version_id: version_id(object), obj_id: object.id, committer_login: user.to_s)
    end

    private

    def version_id(object)
      return object.versions.last.uri if object.has_versions?

      object.uri.to_s
    end
  end
end
