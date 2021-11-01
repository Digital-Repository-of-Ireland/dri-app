# frozen_string_literal: true
module Validators
  # Contains File validator methods for uploaded files

  # Validate the file upload
  #
  # Takes an uploaded file (ActionDispatch::Http::UploadedFile),
  # or a path to a localfile, and calls the required validations.
  #
  def self.validate_file(file, mime_type = nil)
    virus_scan(file)
    valid_file_type?(file, mime_type)
  end

  # Validate file mime-types
  #
  # Takes an uploaded file (ActionDispatch::Http::UploadedFile),
  # or a path to a localfile, and a list of allowed mime
  # types and subtypes.
  #
  # First it gets the mime-type of the file using the mimemagic gem
  #
  # Then checks that the original extension of the uploaded file is valid for that mime-type
  #
  # Finally it compares the mime-type to a whitelist of allowed mime-types which is stored in
  # a class variable for the object type (e.g. in DRI:Model:Audio)
  #
  def self.valid_file_type?(file, mime_type)
    _path, extension = file_path(file)

    # MimeMagic could return null if it can't find a match. If so raise UnknownMimeType error
    raise DRI::Exceptions::UnknownMimeType unless mime_type

    # Ensure that the file extension matches the mime type
    raise DRI::Exceptions::WrongExtension unless extension_matches?(extension, mime_type)

    lc_mime_type = mime_type.to_s.downcase
    raise DRI::Exceptions::InappropriateFileType unless restricted_types.include?(lc_mime_type)

    # If we haven't encountered a problem we return true
    true
  end # End validate_file_type method

  def self.extension_matches?(extension, mime_type)
    mime_types = MIME::Types.type_for(extension)
    mime_types.include?(mime_type) || mime_types.any? { |extension_mime| mime_type.include? extension_mime.sub_type }
  end

  # Returns a MimeMagic or Mime::Types object
  def self.file_type(file)
    init_types

    path, extension = file_path(file)
    mime_type = Marcel::MimeType.for File.open(path)
    return mime_type if mime_type.present?

    # If we can't determine from file structure, then determine by extension
    extension_results = MIME::Types.type_for(extension)
    return nil if extension_results.empty?

    mime_type = extension_results[0]
    mime_type.content_type
  end

  # Returns a MimeMagic or Mime::Types mediatype
  def self.media_type(file)
    init_types

    path, extension = file_path(file)
    mime_type = Marcel::MimeType.for File.open(path)
    return mime_type.split('/', 2)[0] if mime_type.present?

    # If we can't determine from file structure, then determine by extension
    extension_results = MIME::Types.type_for(extension)
    mime_type = extension_results[0] unless extension_results.empty?

    mime_type
  end

  # Performs a virus scan on a single file
  #
  # Throws an exception if a virus is detected
  #
  def self.virus_scan(file)
    if defined? Clamby
      Rails.logger.info 'Performing virus scan.'
      result = Clamby.safe?(file.respond_to?(:path) ? file.path : file)
      raise DRI::Exceptions::VirusDetected unless result
    else
      Rails.logger.warn 'Virus scanning is disabled.'
    end
  end

  #
  # Add additional mime types
  #
  def self.init_types
    Marcel::Magic.add('audio/mpeg', { magic: [[0, "\377\372"], [0, "\377\373"], [0, "\377\362"], [0, "\377\363"]] })
    Marcel::Magic.add('audio/mp2', { extensions: 'mp2, mpeg', magic: [[0, '\377\364'], [0, '\377\365'], [0, '\377\374'], [0, '\377\375']] })
  end

  def self.restricted_types
    Settings.restrict.mime_types.image
            .concat(Settings.restrict.mime_types.text)
            .concat(Settings.restrict.mime_types.pdf)
            .concat(Settings.restrict.mime_types.audio)
            .concat(Settings.restrict.mime_types.video)
  end

  def self.file_path(file)
    if file.class.to_s == 'ActionDispatch::Http::UploadedFile' || file.respond_to?(:original_filename)
      path = file.tempfile.path
      extension = file.original_filename.split('.').last
    elsif file.class.to_s == 'Tempfile' || file.respond_to?(:path)
      path = file.path
      extension = file.path.split('.').last
    else
      path = file
      extension = file.split('.').last
    end

    [path, extension]
  end
end
