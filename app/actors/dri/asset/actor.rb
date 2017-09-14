module DRI
  module Asset
    class Actor
      attr_reader :generic_file, :user

      def initialize(generic_file, user)
        @generic_file = generic_file
        @user = user
      end

      def create_external_content(file_upload, path, filename, mime_type)
        create_content(file_upload, filename, path, mime_type)
      end

      def update_external_content(file_upload, path, filename, mime_type)
        create_content(file_upload, filename, path, mime_type)
      end

    # in order to avoid two saves in a row, create_metadata does not save the file by default.
    # it is typically used in conjunction with create_content, which does do a save.
    # If you want to save when using create_metadata, you can do this:
    #   create_metadata(batch_id) { |gf| gf.save }
    def create_metadata(digital_object_id)
      generic_file.apply_depositor_metadata(user)
      time_in_utc = DateTime.now.new_offset(0)
      generic_file.date_uploaded = time_in_utc
      generic_file.date_modified = time_in_utc
      generic_file.creator = [user.name]

      if digital_object_id
        generic_file.digital_object_id = digital_object_id
      else
        ActiveFedora::Base.logger.warn "unable to find digital object to attach to"
      end
      yield(generic_file) if block_given?
    end

    def create_content(file, filename, path, mime_type)
      generic_file.add_file(file, { path: path, file_name: "#{generic_file.noid}_#{filename}", mime_type: mime_type })

      generic_file.label = filename
      generic_file.title = [generic_file.label] if generic_file.title.blank?
      
      save_characterize_and_record_committer
    end

    def revert_content(revision_id)
      generic_file.content.restore_version(revision_id)
      generic_file.content.create_version
      save_characterize_and_record_committer
    end

    def update_metadata(attributes, visibility)
      generic_file.attributes = attributes
      update_visibility(visibility)
      generic_file.date_modified = DateTime.now
      remove_from_feature_works if generic_file.visibility_changed? && !generic_file.public?
      save_and_record_committer
    end

    def destroy
      generic_file.destroy
    end

    # Takes an optional block and executes the block if the save was successful.
    def save_characterize_and_record_committer
      save_and_record_committer { push_characterize_job }.tap do |val|
        yield if block_given? && val
      end
    end

    # Takes an optional block and executes the block if the save was successful.
    # returns false if the save was unsuccessful
    def save_and_record_committer
      save_tries = 0
      begin
        return false unless generic_file.save
      rescue RSolr::Error::Http => error
        ActiveFedora::Base.logger.warn "DRI::Asset::Actor::save_and_record_committer Caught RSOLR error #{error.inspect}"
        save_tries += 1
        # fail for good if the tries is greater than 3
        raise error if save_tries >= 3
        sleep 0.01
        retry
      end
      yield if block_given?
      generic_file.record_version_committer(user)
      true
    end

    def push_characterize_job
      DRI.queue.push(CharacterizeJob.new(@generic_file.noid))
    end

    protected

      # This method can be overridden in case there is a custom approach for visibility (e.g. embargo)
      def update_visibility(visibility)
        generic_file.visibility = visibility
      end

    private

      def external_mime_type(url)
        "message/external-body; access-type=URL; URL=\"#{url}\""
      end
    end
  end
end
