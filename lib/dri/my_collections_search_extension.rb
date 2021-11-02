# frozen_string_literal: true
module DRI::MyCollectionsSearchExtension
  # Get the previous and next document from a search result
  # @return [Blacklight::Solr::Response, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
  def get_previous_and_next_documents_for_search(index, request_params, extra_controller_params = {})
    p = previous_and_next_document_params(index)

    request_params[:q] = request_params[:q_ws] if request_params[:q_ws].present?
    query = search_builder.with(request_params).start(p.delete(:start)).rows(p.delete(:rows)).merge(extra_controller_params).merge(p)
    response = repository.search(query)

    document_list = response.documents

    # only get the previous doc if there is one
    prev_doc = document_list.first if index.positive?
    next_doc = document_list.last if (index + 1) < response.total

    [response, [prev_doc, next_doc]]
  end
end
