namespace :archives do
  desc 'Remove expired archive files'
  task cleanup: :environment do
    dl_dir = Pathname.new(Settings.dri.downloads)

    collection_cutoff = Settings.archives.collection_dl_retention_period.to_i.days.ago
    object_cutoff = Settings.archives.object_dl_retention_period.to_i.days.ago

    unless dl_dir.directory?
      Rails.logger.warn("Download directory does not exist: #{dl_dir}")
      next
    end

    dl_dir.glob('*').each do |file|
      next unless file.file?

      if file.basename.to_s.start_with?("collection_")
        next unless file.mtime < collection_cutoff
      else
        next unless file.mtime < object_cutoff
      end
      
      Rails.logger.info("Removing expired export: #{file}")
      file.delete
    end
  end
end
