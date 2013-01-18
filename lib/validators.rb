module Validators

  # Validate file mime-types
  #
  # Takes an uploaded file (ActionDispatch::Http::UploadedFile), and a list of allowed mime
  # types and subtypes.
  #
  # First it gets the mime-type of the file using the ruby-filemagic gem
  #
  # Then checks that the original extension of the uploaded file is valid for that mime-type
  #
  # Finally it compares the mime-type to a whitelist of allowed mime-types which is stored in
  # a class variable for the object type (e.g. in DRI:Model:Audio)
  #
  def Validators.valid_file_type?(file, allowed_type, allowed_subtypes)

    #Get the mime type of our file
    mime_type_from_content = FileMagic.new(FileMagic::MAGIC_MIME_TYPE).file(file.tempfile.path) # from file content
    type,subtype = mime_type_from_content.split("/")

    # Ensure that the file extension matches the mime type
    extension = file.original_filename.split(".").last
    unless MIME::Types.type_for(extension).include?(mime_type_from_content)
      return false
    end

    unless allowed_type.downcase == type.downcase
      return false
    end

    unless allowed_subtypes.any?{ |s| s.casecmp(subtype)==0 }
      return false
    end

    # If we haven't encountered a problem we return true
    return true

  end  # End validate_file_type method

end  # End Validators module
