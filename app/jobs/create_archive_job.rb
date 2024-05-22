class CreateArchiveJob
  require 'zip'
  require 'digest/md5'
  require 'tmpdir'
  require 'bagit'

  @queue = :create_archive

  def self.perform(object_id, email)
    object = DRI::Identifier.retrieve_object(object_id)

    # Get metadata
    # Get assets if masterfile
    # Get surrogates if read
    # Actually, if not read cannot ever download the archive

    # 'optimised' directory containing all surrogates
    # 'originals' directory containing all master assets if master asset is accessible
    Rails.logger.info "Creating archive package for object #{object.alternate_id}"

    bag_dir = Dir.mktmpdir("#{object.alternate_id}_")
    bag = ::BagIt::Bag.new bag_dir
    bag.write_bag_info({ "Source-Organization" => "Digital Repository of Ireland" })
    bag.write_bag_info(bag_info(object))

    # descMetadata
    metadata = metadata(object)
    bag.add_file(File.join('metadata', 'metadata.xml'), metadata.path)

    # Licence.txt
    licence = licence(object)
    bag.add_file(File.join('metadata', 'Licence.txt'), licence.path)

    copyright = copyright(object)
    bag.add_file(File.join('metadata', 'Copyright.txt'), copyright.path)

    # End User Agreement
    bag.add_file(File.join('metadata', 'End_User_Agreement.txt'), "app/assets/text/End_User_Agreement.txt")

    add_assets_to_bag(object, bag)

    # create the bag
    bag.manifest!

    # pick the filname and location
    tmp = Tempfile.new("#{object.alternate_id}_")
    zipfile = Zip::File.open(tmp.path, Zip::File::CREATE)

    files_to_zip = bag.bag_files + Dir.glob(File.join(bag_dir, '*.txt'))
    files_to_zip.each { |file| zipfile.add(relative_filename(bag_dir, file), file) }

    zipfile.close
    metadata.unlink
    licence.unlink
    copyright.unlink
    FileUtils.remove_dir(bag_dir, force: true)

    JobMailer.archive_ready_mail(File.basename(tmp.path), email, object).deliver_now

    # Move the file to the downloads dir
    FileUtils.mv(tmp.path, Settings.dri.downloads)
    tmp.unlink
  end

  def self.add_assets_to_bag(object, bag)
    checksums = []
    object.generic_files.each do |gf|
      # exclude preservation files
      next if gf.preservation_only?

      if inherited_masterfile_access(object) == "public"
        bag.add_file(File.join('originals', "#{gf.alternate_id}_#{gf.label}"), gf.path)
        checksums << "#{gf.original_checksum.first} originals/#{gf.alternate_id}_#{gf.label}"
      end

      # Get surrogates
      surrogate = file_surrogate(object, gf)
      if surrogate
        bag.add_file(File.join('optimised', "#{gf.alternate_id}_optimised_#{gf.label}"), surrogate)
      end
    end

    if !checksums.empty?
      checksum_file = Tempfile.open('checksums')
      checksum_file.puts(checksums)
      checksum_file.close

      bag.add_file(File.join('metadata', 'checksums.txt'), checksum_file)
    end
  end

  def self.bag_info(object)
    bag_info = {}
    bag_info['Internal-Sender-Identifier'] = object.alternate_id
    bag_info['External-Identifier'] = object.doi if object.doi

    bag_info
  end

  def self.inherited_licence(obj)
    return if obj.nil?
    return obj.licence unless obj.licence.nil?
    inherited_licence(obj.governing_collection)
  end

  def self.inherited_copyright(obj)
    return if obj.nil?
    return obj.copyright unless obj.copyright.nil?
    inherited_copyright(obj.governing_collection)
  end

  def self.inherited_masterfile_access(obj)
    return if obj.nil?
    return obj.master_file_access unless obj.master_file_access.nil? || obj.master_file_access == "inherit"
    inherited_masterfile_access(obj.governing_collection)
  end

  def self.licence(object)
    licence = Tempfile.new('Licence.txt')
    licence.puts("Rights Statement: #{object.rights.join()}")
    licence.puts("Licence: #{inherited_licence(object)}")
    licence.close

    licence
  end

  def self.copyright(object)
    copyright = Tempfile.new('Copyright.txt')
    copyright.puts("Copyright Statement: #{object.copyright.join()}")
    copyright.puts("Copyright: #{inherited_copyright(object)}")
    copyright.close

    copyright
  end

  def self.metadata(object)
    metadata = Tempfile.new('descMetadata.xml')
    metadata.write(object.attached_files['descMetadata'].content)
    metadata.close

    metadata
  end

  def self.file_surrogate(object, generic_file)
    storage = StorageService.new

    surrogate = Tempfile.new('surrogate')
    storage_url = storage.surrogate_url(object.alternate_id,"#{generic_file.alternate_id}_full_size_web_format") ||
                  storage.surrogate_url(object.alternate_id,"#{generic_file.alternate_id}_webm") ||
                  storage.surrogate_url(object.alternate_id,"#{generic_file.alternate_id}_mp3")

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

  def self.relative_filename(bag_dir, file)
    file[bag_dir.length+1..-1]
  end
end
