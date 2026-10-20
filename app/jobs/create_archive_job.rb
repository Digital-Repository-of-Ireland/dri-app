class CreateArchiveJob
  require 'zip'
  require 'digest/md5'
  require 'tmpdir'
  require 'bagit'

  @queue = :create_archive

  def self.perform(object_id, email)
    object = DRI::Identifier.retrieve_object(object_id)

    bag_dir = create_bag(object)

    begin
      zip_path = zip_bag(bag_dir, object.alternate_id)

      # Move the archive to the downloads directory
      filename = File.basename(zip_path)
      FileUtils.mv(zip_path, Settings.dri.downloads)

      # Notify the user
      JobMailer.archive_ready_mail(filename, email, object).deliver_now
    ensure
      FileUtils.remove_dir(bag_dir) if Dir.exist?(bag_dir)
      FileUtils.rm_f(zip_path) if zip_path
    end
  end

  # Create a BagIt bag and return its directory
  # The caller is responsible for deleting the directory
  def self.create_bag(object)
    Rails.logger.info "Creating archive package for object #{object.alternate_id}"

    bag_dir = Dir.mktmpdir("#{object.alternate_id}_")

    begin
      bag = ::BagIt::Bag.new(bag_dir)

      bag.write_bag_info({ "Source-Organization" => "Digital Repository of Ireland" })
      bag.write_bag_info(bag_info(object))

      # descMetadata
      metadata = metadata(object)
      bag.add_file(File.join('metadata', 'metadata.xml'), metadata.path)

      # Licence
      licence = licence(object)
      bag.add_file(File.join('metadata', 'Licence.txt'), licence.path)

      # Copyright
      copyright = copyright(object)
      bag.add_file(File.join('metadata', 'Copyright.txt'), copyright.path)

      # End User Agreement
      bag.add_file(File.join('metadata', 'End_User_Agreement.txt'), "app/assets/text/End_User_Agreement.txt")

      add_assets_to_bag(object, bag)

      # Finalise the BagIt manifests
      bag.manifest!

      bag_dir
    rescue
      FileUtils.remove_dir(bag_dir) if Dir.exist?(bag_dir)
      raise
    ensure
      metadata&.close!
      licence&.close!
      copyright&.close!
    end
  end


  # Create a ZIP archive from a completed bag
  def self.zip_bag(bag_dir, identifier)
    tmp = Tempfile.new("#{identifier}_")
    zip_path = tmp.path
    tmp.close

    begin
      Zip::File.open(zip_path, create: true) do |zipfile|
        Dir.glob(File.join(bag_dir, '**', '*'), File::FNM_DOTMATCH).each do |file|
          next unless File.file?(file)

          zipfile.add(relative_filename(bag_dir, file), file)
        end
      end

      zip_path
    rescue
      FileUtils.rm_f(zip_path)
      raise
    end
  end



  def self.add_assets_to_bag(object, bag)
    checksums = []
    object.generic_files.each do |gf|
      # exclude preservation files
      next if gf.preservation_only?

      # only include masterfile if it's public
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
    licence.puts("Rights Statement: #{object.rights.join}")
    licence.puts("Licence: #{inherited_licence(object)}")
    licence.close

    licence
  end

  def self.copyright(object)
    copyright = Tempfile.new('Copyright.txt')
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
