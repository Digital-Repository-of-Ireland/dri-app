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

  def convert_file_size_to_next_unit(file_size)
    filesize = file_size / 1024
    filesize = filesize.round(2)
    return filesize
  end

  def get_next_file_unit(file_unit)

    case file_unit.to_s
      when "byte"
        return "kb"
      when "kb"
        return "Mb"
      when "Mb"
        return "Gb"
      when "Gb"
        return "Tb"
      else
        return "?b"
    end

  end

  #filesize in bytes
  def convert_file_size(filesize)
    converted_filesize = {:size => filesize, :unit => 'byte'}
    while (converted_filesize[:size] > 1024) do
      if (get_next_file_unit(converted_filesize[:unit]) == "?b")
        break
      end
      converted_filesize[:size] = convert_file_size_to_next_unit(converted_filesize[:size])
      converted_filesize[:unit] = get_next_file_unit(converted_filesize[:unit])
    end
    return converted_filesize
  end

  def truncate_description description, count
    if (description.length > count)
      return description.first(count)
    else
      return description
    end
  end

end