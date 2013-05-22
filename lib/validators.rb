module Validators

  # Contains File validator methods for uploaded files
 
  require 'mimemagic'

  # Validate the file upload
  #  
  # Takes an uploaded file (ActionDispatch::Http::UploadedFile),
  # or a path to a localfile, and calls the required validations.
  #
  def Validators.validate_file(file, allowed_type, allowed_subtypes)
    self.virus_scan(file)
    self.valid_file_type?(file, allowed_type, allowed_subtypes)
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
  def Validators.valid_file_type?(file, allowed_type, allowed_subtypes)

    self.init_types()

    if file.class.to_s == "ActionDispatch::Http::UploadedFile"
      path = file.tempfile.path
      extension = file.original_filename.split(".").last
    else
      path = file
      extension = file.split(".").last
    end

    #Get the mime type of our file
    mime_type = MimeMagic.by_magic( File.open( path ) )

    # MimeMagic could return null if it can't find a match. If so raise UnknownMimeType error
    raise Exceptions::UnknownMimeType unless mime_type

    # Split out the mime type into type and subtype
    type,subtype = mime_type.to_s.split("/")

    # Ensure that the file extension matches the mime type

    raise Exceptions::WrongExtension unless MIME::Types.type_for(extension).include?(mime_type)

    raise Exceptions::InappropriateFileType unless allowed_type.downcase == type.downcase

    raise Exceptions::InappropriateFileType unless allowed_subtypes.any?{ |s| s.casecmp(subtype)==0 }

    # If we haven't encountered a problem we return true
    return true

  end  # End validate_file_type method

  # Performs a virus scan on a single file
  #
  # Throws an exception if a virus is detected
  #
  def Validators.virus_scan(file)
      if defined? ClamAV
        logger.info "Performing virus scan."
        result = ClamAV.instance.scanfile( file.respond_to?(:path) ? file.path : file )
        raise Exceptions::VirusDetected.new(result) unless result == 0
      else
        logger.warn "Virus scanning is disabled."
      end
  end

  private

    #
    # Add additional mime types
    #
    def Validators.init_types()
      MimeMagic.add( "audio/mpeg", {:magic => [[0, "\377\372"], [0, "\377\373"], [0, "\377\362"], [0, "\377\363"]] } )
      MimeMagic.add( "audio/mp2", {:extensions => "mp2, mpeg", :magic => [[0, "\377\364"], [0, "\377\365"], [0, "\377\374"], [0, "\377\375"] ] } )
    end

end  # End Validators module
