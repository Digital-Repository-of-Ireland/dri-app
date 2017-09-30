require 'dri/model_support/ead_support'
require 'validators'

DRI::ModelSupport::EadSupport.module_eval do
  def add_file(file, original_file_name)
    mime_type = Validators.file_type(file.path)
    pass_validation = false

    begin
      pass_validation = Validators.validate_file(file.path, mime_type)
    rescue Exception => e
      Rails.logger.error "Error validating file: #{e.message}"
      return false
    end

    return false unless pass_validation

    generic_file = DRI::GenericFile.new(noid: DRI::Noid::Service.new.mint)
    generic_file.digital_object = self
    filename = "#{generic_file.noid}_#{original_file_name}"
      
    # Apply depositor metadata, other permissions currently unused for generic files
    ingest_user = UserGroup::User.find_by_email(self.depositor)    
    generic_file.apply_depositor_metadata(self.depositor)

    actor = DRI::Asset::Actor.new(generic_file, ingest_user)
            
    if actor.create_external_content(file, filename, mime_type)
      preservation = Preservation::Preservator.new(self)
      preservation.preserve_assets([filename],[])

      true
    else
      Rails.logger.error "Error saving file: #{e.message}"
      false
    end
  end
end
