class StatsReport
  include ActiveModel::Model

  def self.mime_type_counts
    type_counts = {}

    result = ActiveFedora::SolrService.get('has_model_ssim:"DRI::GenericFile"', facet: true, 'facet.field' => 'file_format_sim')

    facet = result['facet_counts']['facet_fields']['file_format_sim']
    facet.each_slice(2) { |type,count| type_counts[type] = count }
  
    type_counts
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
