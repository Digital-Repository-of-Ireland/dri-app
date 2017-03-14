class Timeline
  include ApplicationHelper

  delegate :can?, :asset_url, :asset_path, :catalog_path, :cover_image_path, :object_file_path, to: :@view

  def initialize(view)
    @view = view
  end
  
  def data(response, tl_field)
    timeline_data = {}
    timeline_data[:events] = []
        
    if response.blank?
      timeline_data[:title] = {}
      timeline_data[:title][:text] = {}
      timeline_data[:title][:text][:headline] = I18n.t('dri.application.timeline.headline.no_results')
      timeline_data[:title][:text][:text] = I18n.t('dri.application.timeline.description.no_results')
    else
      timeline_data[:events] = []
      response.each_with_index do |document, index|
        document = document.symbolize_keys

        title_key = ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string).to_sym
        description_key = ActiveFedora.index_field_mapper.solr_name('description', :stored_searchable, type: :string).to_sym

        dates = document_date(document, tl_field)

        if dates.present?
          start = dates[0]
          end_date = dates[1]
          event = {}
          event[:text] = {}

          event[:start_date] = { year: start.year, month: start.month, day: start.day }
          event[:end_date] = { year: end_date.year, month: end_date.month, day: end_date.day }

          event[:text][:headline] = '<a href="' + catalog_path(document[:id]) + '">' + document[title_key].first + '</a>'
          event[:text][:text] = document[description_key].first.truncate(60, separator: ' ')
          event[:media] = {}
          event[:media][:url] = image(document)
          event[:media][:thumbnail] = image(document)

          timeline_data[:events] << event
        end
      end # for-each
    end

    timeline_data[:events].empty? ? nil : timeline_data.to_json
  end

  def document_date(document, tl_field)
    if document["#{tl_field}Range".to_sym].present?
      ranges = document["#{tl_field}Range".to_sym]

      start_and_end = min_max(ranges)
      return [] if start_and_end.empty?
      
      start_date = start_and_end[0]
      end_date = start_and_end[1]
      
      [ISO8601::DateTime.new(start_date), ISO8601::DateTime.new(end_date)]
    end
  end

  def min_max(ranges)
    start_dates = {}
    end_dates = {}
    ranges.each do |range|
      endpoints = range.gsub(/\[(.*)\]/, '\1').split(/\sTO\s/)

      start_date = endpoints[0]
      end_date = endpoints[1] || start_date
      begin
        start_dates[ISO8601::DateTime.new(start_date).to_f] = start_date
        end_dates[ISO8601::DateTime.new(end_date).to_f] = end_date
      rescue ISO8601::Errors::StandardError => e
        next
      end
    end

    return [] if start_dates.empty?

    min = start_dates.min
    max = end_dates.max

    [ min[1], max[1] ]
  end

  def image(document)
    rel_key = ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)

    files_query = "#{rel_key}:\"#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    image = search_image(document, file_doc) if file_doc && can?(:read, document[:id])
    image = cover_image(document) if image.nil?
    image = default_image(file_doc) if image.nil?

    image
  end

  def surrogate_url(doc, file_doc, name)
    object_file_path(object_id: doc, id: file_doc, surrogate: name)
  end
end