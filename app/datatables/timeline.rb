class Timeline
  include ApplicationHelper

  delegate :can?, :asset_url, :asset_path, :catalog_path, :cover_image_path, :object_file_path, to: :@view

  def initialize(view)
    @view = view
  end
  
  def data(response)
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
        document_date = nil
        document = document.symbolize_keys

        if document[:sdateRange].present?
          document_date = full_date(document[:temporal_coverage_tesim])
          document_date = document[:sdateRange].first if document_date.nil?
        end

        title_key = ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string).to_sym
        description_key = ActiveFedora.index_field_mapper.solr_name('description', :stored_searchable, type: :string).to_sym

        if document_date.present?
          start = document_date[0]
          end_date = document_date[1]
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

    timeline_data.to_json
  end

  def image(document)
    return default_image(file_doc) unless can?(:read, document)

    rel_key = ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)

    files_query = "#{rel_key}:\"#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    image = search_image(document, file_doc) unless file_doc.nil?
    image = cover_image(document) if image.nil?
    image = default_image(file_doc) if image.nil?

    image
  end

  def full_date(dates_array)
    result_date = ''
    date_from = ''
    date_to = ''
    
    dates_array.each do |date|
      next unless DRI::Metadata::Transformations.dcmi_period?(date)
      date.split(/\s*;\s*/).each do |component|
        (k, v) = component.split(/\s*=\s*/)
        if k == 'start'
          date_from = v
        elsif k == 'end'
          date_to = v
        end
      end

      unless date_from.empty?
        date_to = date_from if date_to.empty?

        begin
          sdate_str = ISO8601::DateTime.new(date_from)
          edate_str = ISO8601::DateTime.new(date_to)

          result_date = [ISO8601::DateTime.new(date_from), ISO8601::DateTime.new(date_to)]
          break
        rescue ISO8601::Errors::StandardError
          Rails.logger.error('Timeline helper. Invalid date (non-ISO8601)')
        end
      end
    end

    result_date
  end

  def surrogate_url(doc, file_doc, name)
    object_file_path(object_id: doc, id: file_doc, surrogate: name)
  end
end