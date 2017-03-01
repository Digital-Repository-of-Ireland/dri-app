class Timeline
  delegate :asset_path, :catalog_path, :cover_image_path, :object_file_path, to: :@view

  def initialize(view)
    @view = view
  end
  
  def data(response, queried_date = '')
    timeline_data = { title: {}, events: [] }

    if response.blank?
      timeline_data[:title][:text] = {}
      timeline_data[:title][:text][:headline] = I18n.t('dri.application.timeline.headline.no_results')
      timeline_data[:title][:text][:text] = I18n.t('dri.application.timeline.description.no_results')
    elsif response.size > 120
      timeline_data[:title][:text] = {}
      timeline_data[:title][:text][:headline] = I18n.t('dri.application.timeline.headline.too_many_results')
      timeline_data[:title][:text][:text] = I18n.t('dri.application.timeline.description.too_many_results')
    else
      timeline_data[:title][:text] = {}
      timeline_data[:title][:text][:headline] = I18n.t('dri.application.timeline.headline.results_found')
      timeline_data[:title][:text][:text] = I18n.t('dri.application.timeline.description.results_found')

      timeline_data[:events] = []
      response.each_with_index do |document, index|
        document_date = nil
        document = document.symbolize_keys
        unless document[:sdateRange].nil?
          document_date = full_date(document[:temporal_coverage_tesim], queried_date)
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

    puts timeline_data.to_json
    timeline_data.to_json
  end

  def image(document)
    rel_key = ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)

    files_query = "#{rel_key}:\"#{document[:id]}\""
    files = ActiveFedora::SolrService.query(files_query)
    file_doc = SolrDocument.new(files.first) unless files.empty?

    image = search_image(document, file_doc) unless file_doc.nil?
    image = cover_image(document) if image.nil?
    image = default_image(file_doc) if image.nil?

    image
  end

  def full_date(dates_array, queried_date = '')
    result_date = ''
    date_from = ''
    date_to = ''
    unless queried_date.empty?
      year_from = queried_date.split(' ')[0]
      year_to = queried_date.split(' ')[1]
    end

    dates_array.each do |date|
      next unless DRI::Metadata::Transformations.dcmi_period?(date)
      date.split(/\s*;\s*/).each do |component|
        (k, v) = component.split(/\s*=\s*/)
        if k.eql?('start')
          date_from = v
        elsif k.eql?('end')
          date_to = v
        end
      end

      unless date_from.empty?
        date_to = date_from if date_to.empty?

        begin
          sdate_str = ISO8601::DateTime.new(date_from)
          edate_str = ISO8601::DateTime.new(date_to)

          if queried_date.empty?
            result_date = [ISO8601::DateTime.new(date_from), ISO8601::DateTime.new(date_to)]
            break
          else
            if overlaps?(year_from, sdate_str.year, year_to, edate_str.year)
              result_date = [ISO8601::DateTime.new(date_from), ISO8601::DateTime.new(date_to)]
              break
            end
          end
        rescue ISO8601::Errors::StandardError
          Rails.logger.error('Timeline helper. Invalid date (non-ISO8601)')
        end
      end
    end

    result_date
  end

  def overlaps?(sdate, other_sdate, edate, other_edate)
    (sdate.to_i - other_edate.to_i) * (other_sdate.to_i - edate.to_i) >= 0
  end

  def search_image(document, file_document, image_name = 'crop16_9_width_200_thumbnail.jpg')
    path = nil
    file_type_key = ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)

    unless file_document[file_type_key].blank?
      format = file_document[file_type_key].first
      case format
      when 'image'
        path = surrogate_url(document[:id], file_document.id, image_name)
      when 'text'
        path = surrogate_url(document[:id], file_document.id, 'thumbnail_medium.jpg')
      end
    end

    path
  end

  def default_image(file_document)
    path = 'assets/no_image.png'
    file_type_key = ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)

    unless file_document.nil?
      unless file_document[file_type_key].blank?
        format = file_document[file_type_key].first

        path = asset_path("dri/formats/#{format}.png")
        path = asset_path('no_image.png') if Rails.application.assets.find_asset(path).nil?
      end
    end

    path
  end

  def cover_image(document)
    path = nil
    cover_image_key = ActiveFedora.index_field_mapper.solr_name('cover_image', :stored_searchable, type: :string).to_sym
    root_col_key = ActiveFedora.index_field_mapper.solr_name('root_collection', :stored_searchable, type: :string).to_sym

    if document[cover_image_key] && document[cover_image_key].first
      path = cover_image_url(SolrDocument.new(document))
    elsif !document[root_col_key].blank?
      collection = root_collection_solr_tm(document)
      if collection[cover_image_key] && collection[cover_image_key].first
        path = cover_image_path(SolrDocument.new(collection))
      end
    end

    path
  end

  def root_collection_solr_tm(doc)
    root_col_key = ActiveFedora.index_field_mapper.solr_name('root_collection', :stored_searchable, type: :string).to_sym
    root_col_id_key = ActiveFedora.index_field_mapper.solr_name('root_collection_id', :stored_searchable, type: :string).to_sym

    if doc[root_col_key]
      id = doc[root_col_id_key][0]
      solr_query = "id:#{id}"
      collection = ActiveFedora::SolrService.query(solr_query, defType: 'edismax', rows: '1')
      return collection[0]
    end

    nil
  end

  def surrogate_url(doc, file_doc, name)
    object_file_path(object_id: doc, id: file_doc, surrogate: name)
  end
end