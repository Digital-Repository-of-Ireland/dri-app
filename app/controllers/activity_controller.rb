class ActivityController < ApplicationController
  include Blacklight::AccessControls::Catalog
  include DRI::IIIFViewable

  PER_PAGE = 50

  def show
    id = params[:id]

    @document = SolrDocument.find(id)
    unless access_permitted?
      head :unauthorized, content_type: "text/html"
      return
    end

    formatter = if @document.collection?
                  DRI::Formatters::ActivityStream::OrderedCollection.new(
                    @document,
                    child_count,
                    total_pages
                  )
                else
                  DRI::Formatters::ActivityStream::Activity.new(@document)
                end

    respond_to do |format|
      format.json  { render json: formatter.format, content_type: 'application/ld+json' }
    end
  end

  def page
    collection_id = params[:collection_id]
    page_id = params[:id].to_i

    @document = SolrDocument.find(collection_id)
    unless access_permitted?
      head :unauthorized, content_type: "text/html"
      return
    end

    formatter = DRI::Formatters::ActivityStream::OrderedCollectionPage.new(
                  @document,
                  ordered_items(page_id),
                  page_id,
                  total_pages
                )

    respond_to do |format|
      format.json  { render json: formatter.format, content_type: 'application/ld+json' }
    end
  end

  private

  def access_permitted?
    return true if current_user && current_user.is_admin?

    @document.published? && (@document.collection? || @document.public_read?)
  end

  def child_count
    @child_count ||= ActiveFedora::SolrService.count(ordered_items_query)
  end

  def ordered_items_query
    q_str = child_objects_query

    # with sub-collections
    q_str += " AND ((#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{@document.id}\") OR "

    # or objects with files that are images
    q_str += "(#{ActiveFedora.index_field_mapper.solr_name('file_count', :stored_sortable, type: :integer)}:[1 TO *]"
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('file_type', :facetable)}:\"image\"))"

    q_str
  end


  def ordered_items(page_id)
    query_args = { raw: true,
                   rows: PER_PAGE,
                   sort: 'system_modified_dtsi asc',
                   start: page_id * PER_PAGE
                 }

    result = ActiveFedora::SolrService.get(ordered_items_query, query_args)
    result_docs = result['response']['docs']

    result_docs.map { |r| SolrDocument.new(r) }
  end

  def total_pages
    @total_pages ||= (child_count/PER_PAGE).ceil
  end
end
