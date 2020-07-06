class StatsReport
  include ActiveModel::Model

  def self.file_type_counts
    type_counts = {}

    result = ActiveFedora::SolrService.get(
               'has_model_ssim:"DRI::GenericFile"',
               facet: true,
               'facet.query' => [
                                  'file_type_tesim:image',
                                  'file_type_tesim:text',
                                  'file_type_tesim:video',
                                  'file_type_tesim:audio'
                                ]
             )
    facet = result['facet_counts']['facet_queries']
    facet.each do |key, count|
      type = key.split(':')[1]
      type_counts[type] = count
    end

    type_counts
  end

  def self.mime_type_counts
    type_counts = {}

    result = ActiveFedora::SolrService.get('has_model_ssim:"DRI::Batch"',
                                           facet: true,
                                           'facet.field' => 'mime_type_sim'
                                          )

    facet = result['facet_counts']['facet_fields']['mime_type_sim']
    facet.each_slice(2) do |type,count|
      next if count == 0
      type_counts[type] = count
    end

    type_counts
  end

  def self.file_format_counts
    type_counts = {}

    result = ActiveFedora::SolrService.get('has_model_ssim:"DRI::GenericFile"', facet: true, 'facet.field' => 'file_format_sim')

    facet = result['facet_counts']['facet_fields']['file_format_sim']
    facet.each_slice(2) { |type,count| type_counts[type] = count }

    format_summary = {}

    type_counts.each do |type, count|
      next if type.blank?

      common_type = type.split('(')[0].strip
      format_summary[common_type] = if format_summary.key?(common_type)
                                      format_summary[common_type] + count
                                    else
                                      count
                                    end
    end

    format_summary
  end


  def self.summary
    total_objects = ActiveFedora::SolrService.count('has_model_ssim:"DRI::Batch" and is_collection_sim:false')
    total_assets = ActiveFedora::SolrService.count('has_model_ssim:"DRI::GenericFile"')

    { total_objects: total_objects, total_assets: total_assets }
  end

  def self.total_file_size
    stats = ActiveFedora::SolrService.get('*:*', stats: true, 'stats.field' => 'file_size_isi')
    if stats.present? && stats['stats']['stats_fields'].present? && stats['stats']['stats_fields']['file_size_isi'].present?
      stats['stats']['stats_fields']['file_size_isi']['sum']
    else
      0
    end
  end
end
