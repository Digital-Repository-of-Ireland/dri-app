module DRI
  module Asset
    class Actor
      attr_reader :generic_file, :user

      def initialize(generic_file, user)
        @generic_file = generic_file
        @user = user
      end

      def create_external_content(file_upload, filename, mime_type)
        create_content(file_upload, filename, mime_type)
      end

      def update_external_content(file_upload, filename, mime_type)
        create_content(file_upload, filename, mime_type)
      end

      def update_object_version
        # Update object version
        object = generic_file.digital_object
        version = object.object_version || '1'
        object_version = (version.to_i + 1).to_s
        object.object_version = object_version

        begin
          object.save!
        rescue ActiveRecord::ActiveRecordError => e
          logger.error "Could not update object version number for #{object.noid} to version #{object_version}"
          raise Exceptions::InternalError
        end
      end

      def create_content(file_upload, filename, mime_type)
        update_object_version

        generic_file.add_file(file_upload, { file_name: "#{generic_file.noid}_#{filename}", mime_type: mime_type })

        generic_file.label = filename
        generic_file.title = filename if generic_file.title.blank?
      
        save_characterize_and_record_committer
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
        DRI.queue.push(CharacterizeJob.new(generic_file.noid))
      end

      protected

        # This method can be overridden in case there is a custom approach for visibility (e.g. embargo)
        def update_visibility(visibility)
          generic_file.visibility = visibility
        end

    end
  end
end
