module DRI::Object

  class Actor

    attr_reader :object, :user

    def initialize(object, user)
      @object = object
      @user = user
    end

    def version_and_record_committer
      @object.create_version
      VersionCommitter.create(version_id: @object.versions.last.uri, committer_login: @user.to_s)         
    end

  end
end
