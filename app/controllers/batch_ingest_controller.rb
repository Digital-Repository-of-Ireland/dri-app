class BatchIngestController < ApplicationController
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!

  def create
    collection_id = params[:id]
    enforce_permissions!('create_digital_object', collection_id)

    json = params[:batch_ingest]

    if valid_json?(json)
      status = :accepted
      begin
        Resque.enqueue(ProcessBatchIngest, current_user.id, collection_id, params[:batch_ingest])
      rescue Exception => e
        status = :internal_server_error
      end
    else
      status = :bad_request
    end

    respond_to do |format|
      format.json {
          head status: status
      }
    end
  end

  private

  def valid_json?(json)
    JSON.parse(json)  
    return true  
  rescue JSON::ParserError  
    return false  
  end  

end