module TimelineHelper
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  def get_valid_timeline_count params
    query = get_query params
    count = ActiveFedora::SolrService.count(query[:q], :fq => query[:fq], :defType => "edismax")
    return count
  end

  def create_timeline_data(response, queried_date="")
    timeline_data = { :timeline => { :type => "default", :date => [] } }
    document_date = nil

    if response.blank?
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.no_results')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.no_results')
    elsif response.size > 120
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.too_many_results')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.too_many_results')
    else
      timeline_data[:timeline][:headline] = t('dri.application.timeline.headline.results_found')
      timeline_data[:timeline][:text] = t('dri.application.timeline.description.results_found')

      response.each_with_index do |document, index|
        document = document.symbolize_keys
        if (!document[:sdateRange].nil?)
          document_date = get_date_for_display_timeline document[:sdateRange], queried_date
          if !document_date.empty?
            document_date = queried_date
          else
            document_date = document[:sdateRange].first
          end
        end

        timeline_data[:timeline][:date][index] = {}

        unless document_date.nil?
          timeline_data[:timeline][:date][index][:startDate] = document_date.split(' ')[0]
          timeline_data[:timeline][:date][index][:endDate] = document_date.split(' ')[1]

          timeline_data[:timeline][:date][index][:headline] = '<a href="' +  catalog_path(document[:id])+  '">' + document[ActiveFedora::SolrQueryBuilder.solr_name('title', :stored_searchable, type: :string).to_sym].first + '</a>'
          timeline_data[:timeline][:date][index][:text] = truncate(document[ActiveFedora::SolrQueryBuilder.solr_name('description', :stored_searchable, type: :string).to_sym].first, length: 60, separator: ' ')
          timeline_data[:timeline][:date][index][:asset] = {}
          timeline_data[:timeline][:date][index][:asset][:media] = get_cover_image(document)
        end
      end #for-each
    end

    return timeline_data
  end

  private

  def get_date_for_display_timeline document_dates, queried_date
    return "" if queried_date.empty?

    result_date = ""
    year_from = queried_date.split(" ")[0]
    year_to = queried_date.split(" ")[1]
    document_dates.each do |date|
      date_from = date.split(" ")[0]
      date_to = date.split(" ")[1]
      if overlaps?(year_from, date_from, year_to, date_to)
        result_date = queried_date
        break
      end
    end

    return result_date
  end

  # I had to add explicit returns and change the url to the static assets
  def get_cover_image( document )
    files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    if can?(:read, document[:id])
      cover_image = search_image( document, file_doc ) unless file_doc.nil?
    end

    cover_image = cover_image ( document ) if cover_image.nil?

    cover_image = default_image ( file_doc ) if cover_image.nil?

    return cover_image
  end

  def search_image ( document, file_document, image_name = "crop16_9_width_200_thumbnail" )
    path = nil

    unless file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].blank?
      format = file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first
      case format
        when "image"
          path = surrogate_url(document[:id], file_document.id, image_name)
        when "text"
          path = surrogate_url(document[:id], file_document.id, "thumbnail_medium")
      end
    end

    return path
  end

  def default_image ( file_document )
    path = "assets/no_image.png"

    unless file_document.nil?
      unless file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].blank?
        format = file_document[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first

        path = "assets/dri/formats/#{format}.png"

        if Rails.application.assets.find_asset(path).nil?
          path = "assets/no_image.png"
        end
      end
    end

    return path
  end

  def cover_image ( document )
    path = nil

    if document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym] && document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
      path = document[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string).to_sym].first
    elsif !document[ActiveFedora::SolrQueryBuilder.solr_name('root_collection', :stored_searchable, type: :string).to_sym].blank?
      collection = root_collection_solr(document)
      if collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)] && collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)].first
        path = collection[ActiveFedora::SolrQueryBuilder.solr_name('cover_image', :stored_searchable, type: :string)].first
      end
    end

    return path
  end

  def surrogate_url( doc, file_doc, name )

    storage = Storage::S3Interface.new
    url = storage.surrogate_url(doc, file_doc, name)

    return url
  end

  def overlaps?(sdate, other_sdate, edate, other_edate)
    (sdate.to_i - other_edate.to_i) * (other_sdate.to_i - edate.to_i) >= 0
  end

end