require 'moab'

class FixityController < ApplicationController
  include Preservation::PreservationHelpers

  def update
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    enforce_permissions!('edit', params[:id])

    object = DRI::DigitalObject.find_by_noid(params[:id])
    raise DRI::Exceptions::NotFound if object.nil?

    fixity(object)

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: {}, status: :accepted }
    end
  end

  private

  def fixity(object)
    if object.collection?
      fixity_collection(object)
    else
      fixity_object(object)
    end
  end

  def fixity_object(object)
    result = verify(object.noid)

    FixityCheck.create(
          collection_id: object.governing_collection.noid,
          object_id: object.noid,
          verified: result.verified,
          result: result.to_json
    )
    flash[:notice] = t('dri.flash.notice.fixity_check_completed')
  end

  def fixity_collection(collection)
    Resque.enqueue(FixityCollectionJob, collection.noid, current_user.id)
    flash[:notice] = t('dri.flash.notice.fixity_check_running')
  rescue Exception => e
    logger.error "Unable to submit fixity job: #{e.message}"
    flash[:alert] = t('dri.flash.alert.error_fixity_collection', error: e.message)
  end
end
