module ApplicationHelper
  require 'storage/s3_interface'
  require 'uri'

  def surrogate_url(doc_id, file_doc_id, name)
    return nil unless StorageService.new.surrogate_exists?(doc_id, "#{file_doc_id}_#{name}")

    object_file_url(
      object_id: doc_id,
      id: file_doc_id,
      surrogate: name,
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
    )
  end

  def iiif_info_url(doc_id, file_id)
    "#{Settings.iiif.server}/#{doc_id}:#{file_id}/info.json"
  end

  # Called from grid view
  def image_for_search(document)
    files_query = "#{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{document[:id]}\"
                  AND NOT #{ActiveFedora.index_field_mapper.solr_name('preservation_only', :stored_searchable)}:true"
    files = ActiveFedora::SolrService.query(files_query)

    file_doc = nil
    image = nil

    files.each do |file|
      file_doc = SolrDocument.new(file) unless files.empty?
      if can?(:read, document[:id])
        image = search_image(document, file_doc) unless file_doc.nil?
        break if image
      end
    end

    @search_image = image || default_image(file_doc)
  end

  def search_image(document, file_document, image_name = 'crop16_9_width_200_thumbnail')
    path = nil

    if file_document[ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)].present?
      format = file_document[ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)].first

      case format
      when "image"
        path = surrogate_url(document[:id], file_document.id, image_name)
      when "text"
        path = surrogate_url(document[:id], file_document.id, "thumbnail_medium")
      end
    end

    path
  end

  def default_image(file_document)
    path = asset_url("no_image.png")

    if file_document
      if file_document[ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)].present?
        format = file_document[ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)].first

        path = "dri/formats/#{format}.png"

        path = "no_image.png" if Rails.application.assets.find_asset(path).nil?
      end
    end

    asset_url(path)
  end

  def cover_image(doc)
    path = nil

    document = doc.is_a?(SolrDocument) ? doc : SolrDocument.new(doc)

    cover_key = ActiveFedora.index_field_mapper.solr_name('cover_image', :stored_searchable, type: :string).to_sym

    path = if document[cover_key].present? && document[cover_key].first
             cover_image_path(document)
           elsif document[ActiveFedora.index_field_mapper.solr_name('root_collection', :stored_searchable, type: :string).to_sym].present?
             collection = document.root_collection

             if collection[cover_key].present? && collection[cover_key].first
               cover_image_path(collection)
             end
          end

    path
  end

  def count_items_in_collection(collection_id)
    solr_query = collection_children_query(collection_id)

    unless signed_in? && can?(:edit, collection_id)
      solr_query += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end

    ActiveFedora::SolrService.count(solr_query, defType: 'edismax')
  end

  def collection_children_query(collection_id)
    "(#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
    "\" AND is_collection_sim:false)"
  end

  def count_items_in_collection_by_type(collection_id, type)
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"" + collection_id +
                 "\" AND " +
                 "#{ActiveFedora.index_field_mapper.solr_name('file_type_display', :facetable, type: :string)}:"+ type
    unless signed_in? && can?(:edit, collection_id)
      solr_query += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end
    ActiveFedora::SolrService.count(solr_query, defType: 'edismax')
  end

  def has_browse_params?
    has_search_parameters? || !params[:mode].blank? || !params[:search_field].blank? || !params[:view].blank?
  end

  def root?
    request.env['PATH_INFO'] == '/' && request.path.nil? && request.query_string.blank?
  end

  def has_search_parameters?
    params[:q].present? || params[:f].present? || params[:search_field].present?
  end

  # URI Checker
  def uri?(string)
    uri = URI.parse(string)
    %w(http https).include?(uri.scheme)
  rescue URI::BadURIError, URI::InvalidURIError
    false
  end
end
