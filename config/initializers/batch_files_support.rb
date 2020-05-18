require 'dri/model_support/files'
require 'validators'

DRI::ModelSupport::Files.module_eval do

  def add_file(file, dsid='content', original_file_name)
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

    file_content = GenericFileContent.new(user: ingest_user, object: object, generic_file: generic_file)
    if file_content.set_content(file, filename, mime_type, dsid)
      VersionCommitter.create(version_id: 'v%04d' % object.object_version, obj_id: object.noid, committer_login: user.to_s)

      true
    else
      Rails.logger.error "Error saving file: #{e.message}"
      false
    end
  end
end
