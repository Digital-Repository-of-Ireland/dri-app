# frozen_string_literal: true
# Controller for generating a per-object history/audit report
#
class ObjectHistoryController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def show
    # TODO: determine what the permissions should be
    # should read users be able to see any object history
    # e.g. researchers looking for provenance?
    enforce_permissions!('edit', params[:id])

    @object = DRI::Identifier.retrieve_object!(params[:id])
    object_doc = SolrDocument.find(params[:id])
    object_history = ObjectHistory.new(object: object_doc)

    @versions = object_history.audit_trail
    @fixity = object_history.fixity

    respond_to do |format|
      format.html
      format.xml { render xml: object_history.to_premis, content_type: 'text/xml' }
    end
  end

  def download_version
    enforce_permissions!('edit', params[:id])

    object = DRI::Identifier.retrieve_object!(params[:id])
    version_id = params[:version_id]

    zip_file = create_version_zip(object, version_id[1..-1].to_i)

    response.headers['Content-Length'] = File.size?(zip_file).to_s
    send_file zip_file,
              type: "application/zip",
              stream: true,
              buffer: 4096,
              disposition: "attachment; filename=\"#{object.alternate_id}_#{version_id}.zip\";",
              url_based_filename: true
  end

  private

  def create_version_zip(object, version_number)
    preservator = Preservation::Preservator.new(object)
    manifest_path = preservator.manifest_path(object.alternate_id, version_number)

    file_inventory = preservator.file_inventory_from_path(version_number, manifest_path)
    signature_catalog = preservator.signature_catalog_from_path(manifest_path)

    tmp_dir = Dir.mktmpdir("#{object.alternate_id}_")
    tmp_file = Tempfile.new([object.alternate_id, '.zip'])
    bagger = Moab::Bagger.new(file_inventory, signature_catalog, tmp_dir)
    bagger.fill_bag(:reconstructor, Pathname.new(preservator.aip_dir(object.alternate_id)))
    generator = ::DRI::Exporters::ZipFile.new(tmp_dir, tmp_file)
    generator.write

    FileUtils.rm_rf tmp_dir
    tmp_file
  end
end
