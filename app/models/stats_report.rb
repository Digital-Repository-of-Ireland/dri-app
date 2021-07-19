class StatsReport
  include ActiveModel::Model

  SUMMARISE = %w(jpeg jpg tiff png mp4 mpeg mp3 x-wav x-matroska x-msvideo quicktime)

  def self.file_type_counts
    type_counts = {}

    result = Solr::Query.new(
               'has_model_ssim:"DRI::GenericFile"',
               100,
               { facet: true,
                 'facet.query' => [
                                  'file_type_tesim:image',
                                  'file_type_tesim:text',
                                  'file_type_tesim:video',
                                  'file_type_tesim:audio'
                                ]
               }
             ).get
    facet = result['facet_counts']['facet_queries']
    facet.each do |key, count|
      type = key.split(':')[1]
      type_counts[type] = count
    end

    type_counts
  end

  def self.mime_type_counts
    type_counts = {}

    result = Solr::Query.new(
               'has_model_ssim:"DRI::DigitalObject"',
               100,
               {
                 facet: true,
                 'facet.field' => 'mime_type_sim',
                 'facet.limit' => '-1',
                 'facet.mincount' => '1',
                 'facet.sort' => 'count'
               }
             ).get

    facet = result['facet_counts']['facet_fields']['mime_type_sim']
    facet.each_slice(2) do |type,count|
      next if count == 0
      type_counts[type] = count
    end

    type_counts
  end

  def self.file_format_counts
    type_counts = {}

    result = Solr::Query.new(
               'has_model_ssim:"DRI::GenericFile"',
               100,
               {
                 facet: true,
                 'facet.field' => 'file_format_sim',
                 'facet.limit' => '-1',
                 'facet.mincount' => '1',
                 'facet.sort' => 'count'
               }
             ).get

    facet = result['facet_counts']['facet_fields']['file_format_sim']
    facet.each_slice(2) { |type,count| type_counts[type] = count }

    format_summary = {}

    type_counts.each do |type, count|
      next if type.blank?

      common_type = type.split('(')[0].strip
      if SUMMARISE.include?(common_type)
        format_summary[common_type] = if format_summary.key?(common_type)
                                        format_summary[common_type] + count
                                      else
                                        count
                                      end
      else
        format_summary[type] = count
      end
    end

    format_summary
  end


  def self.summary
    total_objects = Solr::Query.new(
                      'has_model_ssim:"DRI::DigitalObject"',
                      100,
                      { fq: 'is_collection_ssi:false' }
                    ).count
    total_assets = Solr::Query.new('has_model_ssim:"DRI::GenericFile"').count

    { total_objects: total_objects, total_assets: total_assets }
  end

  def self.total_file_size
    stats = Solr::Query.new(
              '*:*',
              100,
              { stats: true, 'stats.field' => 'file_size_isi' }
            ).get
    if stats.present? && stats['stats']['stats_fields'].present? && stats['stats']['stats_fields']['file_size_isi'].present?
      stats['stats']['stats_fields']['file_size_isi']['sum']
    else
      0
    end
  end
end
