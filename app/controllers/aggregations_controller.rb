class AggregationsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :admin?

  def update
    @aggregation = Aggregation.find_by(collection_id: params[:id]) || Aggregation.new

    @aggregation.collection_id = params[:aggregation][:collection_id]
    @aggregation.aggregation_id = params[:aggregation][:aggregation_id]
    @aggregation.doi_from_metadata = params[:aggregation][:doi_from_metadata]
    @aggregation.iiif_main = params[:aggregation][:iiif_main]
    @aggregation.comment = params[:aggregation][:comment]
    @aggregation.save
    flash[:notice] = t('dri.flash.notice.updated')

    redirect_to(my_collections_url(params[:id]))
  end

  def edit
    @aggregation = Aggregation.find_or_create_by_collection_id(params[:id])
  end

  def admin?
    raise Blacklight::AccessControls::AccessDenied, t('dri.views.exceptions.access_denied') unless current_user.is_admin?
  end

end
