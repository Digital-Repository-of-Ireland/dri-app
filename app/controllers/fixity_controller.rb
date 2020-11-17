require 'moab'

class FixityController < ApplicationController

  def update
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    enforce_permissions!('edit', params[:id])

    object = DRI::Batch.find(params[:id])
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
    result = Preservation::Preservator.new(object).verify

    FixityCheck.create(
          collection_id: object.root_collection.first,
          object_id: object.id,
          verified: result[:verified],
          result: result.to_json
    )
    flash[:notice] = t('dri.flash.notice.fixity_check_completed')
  end

  def fixity_collection(collection)
    report = FixityReport.create(collection_id: collection.id)

    Resque.enqueue(FixityCollectionJob, report.id, collection.id, current_user.id)
    flash[:notice] = t('dri.flash.notice.fixity_check_running')
  rescue Exception => e
    logger.error "Unable to submit fixity job: #{e.message}"
    flash[:alert] = t('dri.flash.alert.error_fixity_collection', error: e.message)
  end
end
