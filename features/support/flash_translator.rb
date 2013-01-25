module FlashTranslator

  def flash_for(message)

    case message

    when /ingestion/
      "Audio object has been successfully ingested"      

    when /invalid metadata/
      "Invalid XML:"

    when /invalid schema/
      "Validation Errors:"

    when /invalid object/
      "Invalid Object:" 

    when /updating metadata/
      "Metadata has been successfully updated"

    when /file upload/
      "File has been successfully uploaded"

    when /invalid file type/
      "The file does not appear to be a valid type"

    when /invalid email or password/
      "Invalid email or password"

    when /new account/
      "Welcome! You have signed up successfully."

    when /duplicate email/
      "Email has already been taken"

    when /password mismatch/
      "Password doesn't match confirmation"

    when /too short password/
      "Password is too short"

    else "Unknown"
 
    end
  end

end
World(FlashTranslator)
