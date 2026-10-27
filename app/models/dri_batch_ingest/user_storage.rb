# frozen_string_literal: true
module DRIBatchIngest
  module UserStorage
    def self.root
      Pathname.new(Settings.ingest.storage_root).cleanpath
    end

    def self.home_for(email)
      user_dir = root.join(email).cleanpath
      raise ArgumentError, 'invalid user directory' unless user_dir.dirname == root
      user_dir.join('files').to_s
    end

    def self.resolve(email, relative_path)
      home = home_for(email)
      full = Pathname.new(home).join(relative_path.to_s).cleanpath.to_s
      raise ArgumentError, 'path outside user directory' unless full == home || full.start_with?("#{home}/")
      full
    end
  end
end
