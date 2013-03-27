module Validators

  # Contains File validator methods for uploaded files
 
  require 'mimemagic'

  # Validate file mime-types
  #
  # Takes an uploaded file (ActionDispatch::Http::UploadedFile), and a list of allowed mime
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

    #Get the mime type of our file
    mime_type = MimeMagic.by_magic( File.open( file.tempfile.path ) )

    # MimeMagic could return null if it can't find a match. If so return false
    return false unless mime_type

    # Split out the mime type into type and subtype
    type,subtype = mime_type.to_s.split("/")

    # Ensure that the file extension matches the mime type
    extension = file.original_filename.split(".").last
    unless MIME::Types.type_for(extension).include?(mime_type)
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


  private

    #
    # Add additional mime types
    #
    def Validators.init_types()
      MimeMagic.add( "audio/mpeg", {:magic => [[0, "\377\372"], [0, "\377\373"], [0, "\377\362"], [0, "\377\363"]] } )
      MimeMagic.add( "audio/mp2", {:extensions => "mp2, mpeg", :magic => [[0, "\377\364"], [0, "\377\365"], [0, "\377\374"], [0, "\377\375"] ] } )
    end

end  # End Validators module
