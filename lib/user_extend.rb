# frozen_string_literal: true
module UserGroup
  class User
    # Connects this user object to Hydra behaviors.
    # include Hydra::User
    # Connects this user object to Blacklights Bookmarks.
    # include Blacklight::AccessControls::User
    include Blacklight::User
    include HttpAcceptLanguage

    def self.included(klass)
      # Other modules to auto-include
      klass.extend(ClassMethods)
    end

    def to_s
      email
    end

    module ClassMethods
      # This method should find User objects using the user_key you've chosen.
      # By default, uses the unique identifier specified in by devise authentication_keys (ie. find_by_id, or find_by_email).
      # You must have that find method implemented on your user class, or must override find_by_user_key
      def find_by_user_key(key)
        send("find_by_#{Devise.authentication_keys.first}".to_sym, key)
      end
    end
  end
end
