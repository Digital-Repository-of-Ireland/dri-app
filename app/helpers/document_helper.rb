module DocumentHelper

  def get_document_type document

    case document[:file_type_display_tesim].first.to_s.downcase
      when "image"
        return t("dri.data.types.Image")
      when "audio"
        return t("dri.data.types.Sound")
      when "video"
        return t("dri.data.types.MovingImage")
      when "text"
        return t("dri.data.types.Text")
      when "mixed_types"
        return t("dri.data.types.MixedType")
      else
        return t("dri.data.types.Unknown")
    end

  end

  def get_collection_media_type_params collectionId, mediaType
    searchFacets = { :file_type_display_sim => [mediaType], :root_collection_id_sim => [collectionId] }
    searchParams = { :mode => "objects", :search_field => "all_fields", :utf8 => "✓", :f => searchFacets }
    return searchParams
  end

end