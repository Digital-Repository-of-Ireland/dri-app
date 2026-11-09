# frozen_string_literal: true
class DRIBatchIngest::ProcessBatch
  @queue = :process_batch

  def self.perform(batch_id, media_object_ids = nil)
    batch = DRIBatchIngest::IngestBatch.find(batch_id)
    user = UserGroup::User.find(batch.user_ingest.user_id)
    collection_id = batch.collection_id

    media_objects = media_object_ids || batch.media_objects

    media_objects.each do |mo|
      media_object = mo.is_a?(DRIBatchIngest::MediaObject) ? mo : DRIBatchIngest::MediaObject.find(mo)
      ingest_message = process_media_object(media_object, collection_id)

      Resque.enqueue(::ProcessBatchIngest, user.id, collection_id, ingest_message.to_json)
    end
  end

  def self.label_file(master_file)
    master_file.preservation? ? 'preservation' : 'asset'
  end

  def self.metadata_info(metadata)
    metadata_info = {}
    metadata_info['id'] = metadata.id
    metadata_info['label'] = 'metadata'

    if metadata.status_code == 'COMPLETED'
      metadata_info['object_id'] = URI(metadata.file_location).path.split('/').last
    else
      metadata_info['download_spec'] = JSON.parse(metadata.download_spec)
    end

    metadata_info
  end

  def self.process_media_object(mo, collection_id)
    ingest_message = {}
    ingest_message['collection'] = collection_id
    ingest_message['media_object'] = mo.id
    ingest_message['metadata'] = metadata_info(mo.parts.metadata)

    ingest_message['files'] = []
    mo.parts.each do |mf|
      next if mf.metadata? || mf.status_code == 'COMPLETED'

      master_file = {}
      master_file['id'] = mf.id
      master_file['label'] = label_file(mf)

      master_file['download_spec'] = JSON.parse(mf.download_spec)
      ingest_message['files'] << master_file
    end

    ingest_message
  end
end
