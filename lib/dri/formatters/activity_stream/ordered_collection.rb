# frozen_string_literal: true
class DRI::Formatters::ActivityStream::OrderedCollection
  include Rails.application.routes.url_helpers

  CONTEXT = "http://iiif.io/api/discovery/0/context.json"

  def initialize(object_doc, child_count, page_count, options = {})
    @object_doc = object_doc
    @child_count = child_count
    @page_count = page_count
  end

  def format(options = {})
    ordered_collection = IIIF::Discovery::OrderedCollection.new
    ordered_collection.id = activity_url(@object_doc.id, format: :json)
    ordered_collection.total_items = @child_count
    ordered_collection.see_also << [
      {
        id: catalog_url(@object_doc.id, format: :json),
        type: "Dataset",
        format: "application/json"
      }
    ]
    if @object_doc.collection_id
      ordered_collection.part_of << [
        {
          id: activity_url(@object_doc.collection_id, format: :json),
          type: "OrderedCollection"
        }
      ]
    end
    ordered_collection.first = {
      id: activity_page_url(@object_doc.id, 0, format: :json),
      type: "OrderedCollectionPage"
    }
    ordered_collection.last = {
      id: activity_page_url(@object_doc.id, @page_count, format: :json),
      type: "OrderedCollectionPage"
    }
    ordered_collection.to_json
  end
end
