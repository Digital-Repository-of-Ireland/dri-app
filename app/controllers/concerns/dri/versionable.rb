module DRI
  module Versionable
    extend ActiveSupport::Concern

    def record_version_committer(object, user)
      VersionCommitter.create(version_id: version_id(object), obj_id: object.alternate_id, committer_login: user.to_s)
    end

    private

    def version_id(object)
      'v%04d' % object.object_version
    end
  end
end
