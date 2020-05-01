class CreateArchiveJob
  require 'zip'
  require 'digest/md5'

  @queue = :create_archive

  def self.perform(object_id, email)
    object = DRI::Identifier.retrieve_object(object_id)

    # Get metadata
    # Get assets if masterfile
    # Get surrogates if read
    # Actually, if not read cannot ever download the archive

    # 'optimised' directory containing all surrogates
    # 'originals' directory containing all master assets if master asset is accessible

    Rails.logger.info "Creating archive package for object #{object.noid}"

    # pick the filname and location
    tmp = Tempfile.new("#{object.noid}_")
    zipfile = Zip::File.open(tmp.path, Zip::File::CREATE)

    # descMetadata
    metadata = Tempfile.new('descMetadata.xml')
    metadata.write(object.attached_files['descMetadata'].content)
    metadata.close
    zipfile.add("#{object.noid}/descMetadata.xml", metadata.path)

    # Licence.txt
    licence = Tempfile.new('Licence.txt')
    licence.puts("Rights Statement: #{object.rights.join()}")
    licence.puts("Licence: #{get_inherited_licence(object)}")
    licence.close
    zipfile.add("#{object.noid}/Licence.txt", licence.path)

    # End User Agreement
    zipfile.add("#{object.noid}/End_User_Agreement.txt", "app/assets/text/End_User_Agreement.txt")

    checksums = []

    object.generic_files.each do |gf|
      # exclude presevation files
      next if gf.preservation_only == 'true'

      if get_inherited_masterfile_access(object) == "public"
        zipfile.add("#{object.noid}/originals/#{gf.noid}_#{gf.label}", gf.path)
        checksums << "#{gf.original_checksum.first} originals/#{gf.noid}_#{gf.label}"
      end

      # Get surrogates
      surrogate = file_surrogate(object, gf)
      if surrogate
        zipfile.add("#{object.noid}/optimised/#{gf.noid}_optimised_#{gf.label}", surrogate)

        hash = Digest::MD5.hexdigest(File.read(surrogate))
        checksums << "#{hash} optimised/#{gf.noid}_optimised_#{gf.label}"
      end
    end

    md5file = Tempfile.open('checksums')
    md5file.puts(checksums)
    md5file.close

    zipfile.add("#{object.noid}/checksums.md5", md5file)

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

  def self.file_surrogate(object, generic_file)
    storage = StorageService.new

    surrogate = Tempfile.new('surrogate')
    storage_url = storage.surrogate_url(object.noid,"#{generic_file.noid}_full_size_web_format") ||
                  storage.surrogate_url(object.noid,"#{generic_file.noid}_webm") ||
                  storage.surrogate_url(object.noid,"#{generic_file.noid}_mp3")

    return nil unless storage_url

    # handle case of using file storage as well as S3
    if storage_url =~ /\A#{URI.regexp(['http', 'https'])}\z/
      surrogate.binmode
      surrogate.write HTTParty.get(storage_url).parsed_response
      surrogate.close
    else
      FileUtils.cp(storage_url, surrogate.path)
    end

    surrogate
  end
end
