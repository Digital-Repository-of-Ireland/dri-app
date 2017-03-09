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
    if document["#{tl_field}_range_start_isi".to_sym].present?
      start_year = document["#{tl_field}_range_start_isi".to_sym]
      end_year = document["#{tl_field}_range_end_isi"] || start_year
      
      [ISO8601::DateTime.new(start_year.to_s), ISO8601::DateTime.new(end_year.to_s)]
    end
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

  def surrogate_url(doc, file_doc, name)
    object_file_path(object_id: doc, id: file_doc, surrogate: name)
  end
end