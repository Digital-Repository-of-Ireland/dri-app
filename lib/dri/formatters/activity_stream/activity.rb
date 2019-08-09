# frozen_string_literal: true
class DRI::Formatters::ActivityStream::Activity
  include Rails.application.routes.url_helpers

  def initialize(object_doc, options = {})
    @object_doc = object_doc
  end

  def to_activity
    created_time = @object_doc['system_create_dtsi']
    modified_time = @object_doc['system_modified_dtsi']
    type = created_time == modified_time ? 'Create' : 'Update'

    activity = IIIF::Discovery::Activity.new
    activity.id = activity_url(@object_doc.id, format: :json)
    activity.end_time = modified_time
    activity.type = type

    object = IIIF::Discovery::Object.new
    if @object_doc.collection?
      object.type = 'Collection'
      object.id = iiif_collection_manifest_url(@object_doc.id)
    else
      object.type = 'Manifest'
      object.id = iiif_manifest_url(@object_doc.id)
    end

    object.see_also << IIIF::Discovery::SeeAlso.new(
                         'id' => catalog_url(@object_doc.id, format: :json),
                         'format' => "application/json"
                       )
    activity.object = object

    activity
  end

  def format(options = {})
    to_activity.to_json
  end
end
