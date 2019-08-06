# frozen_string_literal: true
class DRI::Formatters::ActivityStream::OrderedCollectionPage
  include Rails.application.routes.url_helpers

  CONTEXT = "http://iiif.io/api/discovery/0/context.json"

  def initialize(object_doc, ordered_items, page_id, total_pages, options = {})
    @object_doc = object_doc
    @page_id = page_id
    @total_pages = total_pages
    @ordered_items = ordered_items
  end

  def format(options = {})
    page = {
      "@context": CONTEXT,
      id: activity_page_url(@object_doc.id, @page_id, format: :json)
    }
    page[:type] = "OrderedCollectionPage"
    page[:partOf] = activity_url(@object_doc.id, format: :json)

    if @page_id > 0
      page[:prev] = {
        id: activity_page_url(@object_doc.id, page_id - 1, format: :json),
        type: "OrderedCollectionPage"
      }
    end

    if @page_id < @total_pages - 1
      page[:next] = {
        id: activity_page_url(@object_doc.id, page_id + 1, format: :json),
        type: "OrderedCollectionPage"
      }
    end

    page[:ordered_items] = @ordered_items.map do |item|
      DRI::Formatters::ActivityStream::Activity.new(item).to_activity
    end

    page.to_json
  end
end
