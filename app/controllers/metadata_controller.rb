TITLES = {
  'qualifieddc' => 'Dublin Core Metadata',
  'record' => 'MARC Metadata',
  'mods' => 'MODS Metadata',
  'ead' => 'EAD Metadata',
  'c' => 'EAD Metadata',
  'RDF' => 'Dublin Core Metadata (in RDF/XML)'
}.freeze

#
# Creates, updates, or retrieves, the descMetadata datastream for an object
#
class MetadataController < ApplicationController
  include DRI::Citable
  include DRI::Duplicable
  include DRI::Versionable

  before_action :authenticate_user_from_token!, except: :show
  before_action :authenticate_user!, except: :show
  before_action :read_only, except: :show
  before_action ->(id = params[:id]) { locked(id) }, except: :show

  # Renders the metadata XML stored in the descMetadata datastream.
  #
  def show
    enforce_permissions!('show_digital_object', params[:id])
    begin
      @object = retrieve_object! params[:id]
    rescue DRI::Exceptions::InternalError
      @title = status_to_message(:internal_server_error)
    rescue ActiveFedora::ObjectNotFoundError
      render xml: { error: 'Not found' }, status: 404
      return
    end

    unless object_with_metadata
      respond_to do |format|
        format.js do
          @display_xml = t('dri.views.exceptions.internal_error')
        end
        format.xml do
          render xml: { error: t('dri.views.exceptions.internal_error') }, status: 500
        end
      end

      return
    end

    respond_to do |format|
      format.xml do
        data = if @object.attached_files.key?(:fullMetadata) && @object.attached_files[:fullMetadata].content
                 @object.attached_files[:fullMetadata].content
               else
                 @object.attached_files[:descMetadata].content
               end
        send_data(data, filename: "#{@object.id}.xml")
        return
      end
      format.js do
        xml_data = @object.attached_files[:descMetadata].content
        xml = Nokogiri::XML(xml_data)

        @title = TITLES[xml.root.name]
        @display_xml = styled_xml(xml).to_html
        return
      end
    end

    render plain: 'Unable to load metadata'
  end

  # Replaces the current descMetadata datastream with the contents of the uploaded XML file.
  #
  def update
    enforce_permissions!('update', params[:id])

    param = params[:xml].presence || params[:metadata_file].presence

    if param
      xml_ds = XmlDatastream.new
      xml_ds.load_xml(param)
    else
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
      redirect_to controller: 'catalog', action: 'show', id: params[:id]
      return
    end

    @object = retrieve_object!(params[:id])
    @errors = nil

    unless can? :update, @object
      raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, '')
    end

    @object.update_metadata(xml_ds.xml)

    if @object.valid?
      checksum_metadata(@object)
      warn_if_has_duplicates(@object)

      @object.increment_version

      begin
        raise DRI::Exceptions::InternalError unless @object.save

        record_version_committer(@object, current_user)
        update_or_mint_doi

        retrieve_linked_data if AuthoritiesConfig

        preservation = Preservation::Preservator.new(@object)
        preservation.preserve(false, false, ['descMetadata', 'properties'])

        flash[:notice] = t('dri.flash.notice.metadata_updated')
      rescue RuntimeError => e
        logger.error "Could not save object #{@object.noid}: #{e.message}"
        raise DRI::Exceptions::InternalError
      end
    else
      flash[:alert] = t('dri.flash.alert.invalid_object', error: @object.errors.full_messages.inspect)
      @errors = @object.errors.full_messages.inspect
    end

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: params[:id] }
      format.json { render json: @object }
      format.text do
        response = if @errors
                     t('dri.flash.alert.invalid_object', error: @errors)
                   else
                     t('dri.flash.notice.metadata_updated')
                   end

        render plain: response
      end
    end
  end

  private

    def object_with_metadata
      @object && @object.attached_files.key?(:descMetadata)
    end

    def styled_xml(xml)
      xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
      xslt = Nokogiri::XSLT(xslt_data)
      xslt.transform(xml)
    end

    def update_or_mint_doi
      doi = DataciteDoi.find_by(object_id: @object.noid)
      return unless doi

      doi_metadata_fields = {}
      doi.metadata_fields.each do |field|
        doi_metadata_fields[field] = @object.send(field.to_sym)
      end
      doi.update_metadata(doi_metadata_fields)
      update_doi(@object, doi, 'metadata update') if doi.changed?
    end

    def retrieve_linked_data
      DRI.queue.push(LinkedDataJob.new(@object.noid)) if @object.geographical_coverage.present? || @object.coverage.present?
    rescue Exception => e
      Rails.logger.error "Unable to submit linked data job: #{e.message}"
    end
end
