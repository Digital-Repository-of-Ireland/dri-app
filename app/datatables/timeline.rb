class Timeline
  include ApplicationHelper

  TITLE_KEY = ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string).to_sym
  DESCRIPTION_KEY = ActiveFedora.index_field_mapper.solr_name('description', :stored_searchable, type: :string).to_sym

  delegate :can?, :asset_url, :asset_path, :link_to, :url_for_document, :cover_image_path, :object_file_path, to: :@view

  def initialize(view)
    @view = view
  end

  def data(response, tl_field)
    timeline_data = []

    response.each_with_index do |document, index|
      document = document.symbolize_keys

      dates = document_date(document, tl_field)
      next unless dates.present?

      event = create_event(document, dates)
      timeline_data << event
    end

    timeline_data
  end

  def create_event(document, dates)
    start = dates[0]
    end_date = dates[1]

    event = {}
    event[:text] = {}
    event[:start_date] = { year: start.year, month: start.month, day: start.day }
    event[:end_date] = { year: end_date.year, month: end_date.month, day: end_date.day }
    event[:text][:headline] = link_to(document[TITLE_KEY].first, url_for_document(document[:id]))
    event[:text][:text] = document[DESCRIPTION_KEY].first.truncate(60, separator: ' ')
    event[:media] = {}
    event[:media][:url] = image(document)
    event[:media][:thumbnail] = image(document)

    event
  end


  def document_date(document, tl_field)
    # using date_range_start_isi not ddate, so need to modify to find
    # ddateRange field
    tl_field = 'ddate' if tl_field == 'date'

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
    solr_doc = SolrDocument.new(document)
    files = solr_doc.assets

    presenter = DRI::ImagePresenter.new(document, @view)
    file_types = document[presenter.file_type_key]

    return presenter.default_image(file_types) unless can?(:read, document[:id])

    image = nil

    files.each do |file|
      image = presenter.search_image(file)
      break if image
    end

    image || presenter.cover_image || presenter.default_image(file_types)
  end
end
