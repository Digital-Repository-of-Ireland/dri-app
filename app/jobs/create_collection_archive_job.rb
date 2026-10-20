class CreateCollectionArchiveJob
  require 'zip'
  require 'tmpdir'
  require 'fileutils'

  @queue = :create_archive

  def self.perform(collection_id, email)
    collection = DRI::Identifier.retrieve_object(collection_id)

    raise ArgumentError, "Not a collection: #{collection_id}" unless collection.collection?

    Rails.logger.info "Creating archive for collection #{collection.alternate_id}"

    zip_path = nil

    begin
      Dir.mktmpdir("collection_#{collection.alternate_id}_") do |workspace|

        # Create one BagIt bag for each object
        collection.governed_items.each do |object|
          Rails.logger.info "Adding #{object.alternate_id} to collection archive"

          bag_dir = CreateArchiveJob.create_bag(object)

          destination = File.join(workspace, object.alternate_id)

          begin
            FileUtils.mv(bag_dir, destination)
          ensure
            FileUtils.remove_dir(bag_dir) if Dir.exist?(bag_dir)
          end
        end

        # Create a single ZIP containing all the bags
        zip_path = zip_collection(workspace, collection.alternate_id)
      end

      # Move the ZIP to the downloads directory
      filename = File.basename(zip_path)
      FileUtils.mv(zip_path, Settings.dri.downloads)

      # Notify the user
      JobMailer.collection_archive_ready_mail(filename, email, collection).deliver_now

    ensure
      FileUtils.rm_f(zip_path) if zip_path
    end
  end

  def self.zip_collection(workspace, identifier)
    zip_path = File.join(
      Dir.tmpdir,
      "#{identifier}_#{SecureRandom.hex(8)}"
    )

    begin
      Zip::File.open(zip_path, create: true) do |zipfile|
        Dir.glob(File.join(workspace, '**', '*'), File::FNM_DOTMATCH).each do |file|
          next unless File.file?(file)

          relative_path = file.delete_prefix("#{workspace}/")
          zipfile.add(relative_path, file)
        end
      end

      zip_path
    rescue
      FileUtils.rm_f(zip_path)
      raise
    end
  end
end

