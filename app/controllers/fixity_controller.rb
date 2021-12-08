# frozen_string_literal: true
require 'moab'

class FixityController < ApplicationController
  def update
    raise DRI::Exceptions::BadRequest if params[:id].blank?
    enforce_permissions!('edit', params[:id])

    object = DRI::DigitalObject.find_by_alternate_id(params[:id])
    raise DRI::Exceptions::NotFound if object.nil?
    fixity(object)

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: {}, status: :accepted }
    end
  end

  private

  def fixity(object)
    object.collection? ? fixity_collection(object) : fixity_object(object)
  end

  def fixity_object(object)
    result = Preservation::Preservator.new(object).verify
    root_collection_id = object.to_solr['root_collection_id_ssi']
    report = FixityReport.create(collection_id: root_collection_id)

    FixityCheck.create(
          fixity_report_id: report.id,
          collection_id: object.to_solr['root_collection_id_ssi'],
          object_id: object.alternate_id,
          verified: result[:verified],
          result: result.to_json
        )
    flash[:notice] = t('dri.flash.notice.fixity_check_completed')
  end

  def fixity_collection(collection)
    report = FixityReport.create(collection_id: collection.alternate_id)
    Resque.enqueue(FixityCollectionJob, report.id, collection.alternate_id, current_user.id)
    flash[:notice] = t('dri.flash.notice.fixity_check_running')
  rescue Redis::CannotConnectError => e
    logger.error "Unable to submit fixity job: #{e.message}"
    flash[:alert] = t('dri.flash.alert.error_fixity_collection', error: e.message)
  end
end
