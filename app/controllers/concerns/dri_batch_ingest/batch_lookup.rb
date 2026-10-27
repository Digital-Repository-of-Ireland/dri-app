module DRIBatchIngest
  module BatchLookup
    extend ActiveSupport::Concern

    private

    def find_user_batch(id)
      raise ActiveRecord::RecordNotFound unless current_user

      DRIBatchIngest::IngestBatch
        .where(user_ingest_id: DRIBatchIngest::UserIngest.where(user_id: current_user.id).select(:id))
        .find(id)
    end
  end
end