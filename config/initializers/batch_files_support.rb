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

    generic_file = DRI::GenericFile.new(id: DRI::Noid::Service.new.mint)
    generic_file.batch = self
    filename = "#{generic_file.id}_#{original_file_name}"

    # Apply depositor metadata, other permissions currently unused for generic files
    ingest_user = UserGroup::User.find_by_email(self.depositor)
    generic_file.apply_depositor_metadata(self.depositor)

    self.object_version ||= '1'
    self.increment_version

    # Update object version
    begin
      self.save!
    rescue ActiveRecord::ActiveRecordError => e
      logger.error "Could not update object version number for #{self.id} to version #{object_version}"
      raise Exceptions::InternalError
    end

    LocalFile.build_local_file(
      object: self,
      generic_file: generic_file,
      data: file,
      datastream: dsid,
      opts: { filename: filename, mime_type: mime_type, checksum: 'md5' }
    )

    preservation = Preservation::Preservator.new(self)
    preservation.preserve_assets([filename],[])

    url = Rails.application.routes.url_helpers.url_for(
      controller: 'assets',
      action: 'download',
      object_id: self.id,
      id: generic_file.id,
      version: object_version
    )

    file_content = GenericFileContent.new(user: ingest_user, object: object, generic_file: generic_file)
    if file_content.external_content(URI.escape(url), filename, dsid)
      true
    else
      Rails.logger.error "Error saving file: #{e.message}"
      false
    end
  end
end
