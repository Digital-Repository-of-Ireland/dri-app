require 'dri/model_support/ead_support'
require 'validators'

DRI::ModelSupport::EadSupport.module_eval do

  def add_file_to_object(file, original_file_name, dsid='content')
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

    file_content = GenericFileContent.new(
                       user: ingest_user,
                       object: self,
                       generic_file: generic_file
                     )

    filedata = {
      file_upload: file,
      filename: original_file_name,
      mime_type: mime_type
    }

    file_content.add_content(filedata)

    VersionCommitter.create(version_id: 'v%04d' % self.object_version, obj_id: self.noid, committer_login: ingest_user.to_s)
    true
  end
end
