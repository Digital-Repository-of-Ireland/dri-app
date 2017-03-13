class CreateArchiveJob
  require 'zip'

  @queue = :create_archive

  def self.perform(object_id, email) 
      object = ActiveFedora::Base.find(object_id, cast: true)

      # Get metadata
      # Get assets if masterfile
      # Get surrogates if read
      # Actually, if not read cannot ever download the archive

      # 'optimised' directory containing all surrogates
      # 'originals' directory containing all master assets if master asset is accessible

      Rails.logger.info "Creating archive package for object #{object.id}"

      # pick the filname and location
      tmp = Tempfile.new("#{object.id}_")
      zipfile = Zip::File.open(tmp.path, Zip::File::CREATE)

      # descMetadata
      metadata = Tempfile.new('descMetadata.xml')
      metadata.write(object.attached_files['descMetadata'].content)
      metadata.close
      zipfile.add("#{object.id}/descMetadata.xml", metadata.path)

      # Licence.txt
      licence = Tempfile.new('Licence.txt')
      licence.puts("Rights Statement: #{object.rights.join()}")
      licence.puts("Licence: #{get_inherited_licence(object)}")
      licence.close
      zipfile.add("#{object.id}/Licence.txt", licence.path)

      storage = StorageService.new

      object.generic_files.each do |gf|
        if get_inherited_masterfile_access(object) == "public"
          lf = LocalFile.where('fedora_id LIKE :f AND ds_id LIKE :d', f: gf.id, d: 'content').order('version DESC').to_a.first
          zipfile.add("#{object.id}/originals/#{gf.id}_#{gf.label}", lf.path)
        end

        # Get surrogates
        surrogate = Tempfile.new('surrogate')
        surrogate.binmode
        surrogate.write HTTParty.get(storage.surrogate_url(object.id,"#{gf.id}_full_size_web_format")).parsed_response
        surrogate.close
        zipfile.add("#{object.id}/optimised/#{gf.id}_optimised_#{gf.label}", surrogate)
      end

      zipfile.close
      metadata.unlink
      licence.unlink

      # raise "Unable to create storage bucket" unless created
      JobMailer.archive_ready_mail(File.basename(tmp.path), email, object).deliver_now

      # Move the file to the downloads dir
      FileUtils.mv(tmp.path, Settings.dri.downloads)
      tmp.unlink
  end

  def self.get_inherited_licence(obj)
    return if obj == nil
    return obj.licence unless obj.licence == nil
    get_inherited_licence(obj.governing_collection)
  end

  def self.get_inherited_masterfile_access(obj)
    return if obj == nil
    return obj.master_file_access unless obj.master_file_access == "inherit" || obj.master_file_access == nil
    get_inherited_masterfile_access(obj.governing_collection)
  end

end
