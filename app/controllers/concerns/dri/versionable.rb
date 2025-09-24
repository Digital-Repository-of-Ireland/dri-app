module DRI
  module Versionable
    extend ActiveSupport::Concern

    def record_version_committer(object, user, event = nil)
      version_params = { 
        version_id: version_id(object), 
        obj_id: object.alternate_id, 
        committer_login: user.to_s
      }
      version_params[:event] = event if event
      
      VersionCommitter.create(version_params)
    end

    private

    def version_id(object)
      'v%04d' % object.object_version
    end
  end
end
