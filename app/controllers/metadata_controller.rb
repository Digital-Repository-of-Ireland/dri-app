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
    rescue DRI::Exceptions::BadRequest
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
        data = if full_metadata_has_content?
                 @object.attached_files[:fullMetadata].content
               else
                 @object.attached_files[:descMetadata].content
               end
        send_data(data, filename: "#{@object.alternate_id}.xml")
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
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, '')
    end

    @object.update_metadata(xml_ds.xml)

    if @object.valid?
      checksum_metadata(@object)
      warn_if_has_duplicates(@object)

      @object.increment_version

      begin
        unless save_and_index
          logger.error "Could not save object #{@object.alternate_id}"
          raise DRI::Exceptions::InternalError
        end

        record_version_committer(@object, current_user)
        flash[:notice] = t('dri.flash.notice.metadata_updated')

        update_or_mint_doi
        mint_or_update_doi(@object, @doi) if @doi

        preservation = Preservation::Preservator.new(@object)
        preservation.preserve(['descMetadata'])

        retrieve_linked_data if AuthoritiesConfig
      rescue DRI::SolrBadRequest => e
        flash[:alert] = t('dri.flash.alert.invalid_object', error: e.details)
        @errors = e.details
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

    def full_metadata_has_content?
      return false unless @object.attached_files.key?(:fullMetadata)

      @object.attached_files[:fullMetadata]&.ng_xml.present? && @object.attached_files[:fullMetadata].ng_xml.root.children.present?
    end

    def object_with_metadata
      @object && @object.attached_files.key?(:descMetadata)
    end

    def styled_xml(xml)
      xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
      xslt = Nokogiri::XSLT(xslt_data)
      xslt.transform(xml)
    end

    def update_or_mint_doi
      @doi = DataciteDoi.find_by(object_id: @object.alternate_id)
      return unless @doi

      doi_metadata_fields = {}
      @doi.metadata_fields.each do |field|
        doi_metadata_fields[field] = @object.send(field.to_sym)
      end
      @doi.update_metadata(doi_metadata_fields)
      new_doi_if_required(@object, @doi, 'metadata updated')
    end

    def retrieve_linked_data
      DRI.queue.push(LinkedDataJob.new(@object.alternate_id)) if @object.geographical_coverage.present? || @object.coverage.present?
    rescue Exception => e
      Rails.logger.error "Unable to submit linked data job: #{e.message}"
    end

    def save_and_index
      @object.index_needs_update = false

      DRI::DigitalObject.transaction do
        begin
          raise ActiveRecord::Rollback unless @object.save && @object.update_index

          return true
        rescue RSolr::Error::Http
          raise ActiveRecord::Rollback
        end
      end

      false
    end
end
