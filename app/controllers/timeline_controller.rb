class TimelineController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include TimelineHelper

  def get
    response = []
    query = get_query(params)
    puts "retrievieng objects based on the following query:"
    puts query

    # Retrieve all Solr documents in chunks (of 40)
    q_result = Solr::Query.new(query[:q], 40, :fq => query[:fq])

    while (q_result.has_more?)
      objects_docs = q_result.pop
      objects_docs.each do |obj_doc|
        response << SolrDocument.new(obj_doc)
      end
    end

    # This only returns 40 for now - replace with Solr call above
    #response = ActiveFedora::SolrService.query(query[:q], :fq => query[:fq], :defType => "edismax", :rows => "40")

    # ######## parsing dates examples
    # ######## TO BE REMOVED BEGIN
    # iso_date = "1986-02-18"
    # w3c_date = "Wed, 09 Feb 1994"
    # dcmi_date = "name=Phanerozoic Eon; end=2009-09-25T16:40+10:00; start=1999-09-25T14:20+10:00; scheme=W3C-DTF;"
    # iso_conv_date = Date.parse(iso_date)
    # w3c_conv_date = Date.parse(w3c_date)
    # parsed_dcmi = parse_dcmi(dcmi_date)
    # puts parse_dcmi?(w3c_date).to_s
    # puts iso_conv_date.inspect
    # puts w3c_conv_date.inspect
    # puts parse_dcmi?(dcmi_date).to_s
    # puts parsed_dcmi.inspect
    # puts Solrizer.solr_name('description', :stored_searchable, type: :string)
    # ######## TO BE REMOVED END

    timeline_data = create_timeline_data(response)

    render :json => timeline_data.to_json
  end

  private

  def parse_dcmi dcmi_date
    parsed_dcmi = {}
    return 'nil' if dcmi_date.nil?

    dcmi_date.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if (k == 'start' || k == 'end')
        parsed_dcmi[k.to_sym] = Date.parse(v).to_s.gsub(/[-]/, ',')
      end
    end

    if parsed_dcmi.blank?
      return dcmi_date
    end

    return parsed_dcmi
  end

  def parse_dcmi? dcmi_date
    return dcmi_date != parse_dcmi(dcmi_date)
  end

  def create_timeline_data(response)
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
          document_date = document[:sdateRange].first
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

end
