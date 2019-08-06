# frozen_string_literal: true
class DRI::Formatters::ActivityStream::Activity
  include Rails.application.routes.url_helpers

  def initialize(object_doc, options = {})
    @object_doc = object_doc
  end

  def to_activity
    activity = {id: activity_url(@object_doc.id, format: :json)}
    created_time = @object_doc['system_create_dtsi']
    modified_time = @object_doc['system_modified_dtsi']

    type = created_time == modified_time ? 'Create' : 'Update'
    activity[:type] = type
    activity[:endTime] = modified_time

    object = {}
    if @object_doc.collection?
      object[:id] = iiif_manifest_url(@object_doc.id)
      object[:type] = 'Collection'
    else
      object[:id] = iiif_collection_manifest_url(@object_doc.id)
      object[:type] = 'Manifest'
    end

    object[:seeAlso] = [
      {
        id: catalog_url(@object_doc.id, format: :json),
        type: "Dataset",
        format: "application/json"
      }
    ]
    activity[:object] = object

    activity
  end

  def format(options = {})
    to_activity.to_json
  end
end
