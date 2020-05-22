class StatsReport
  include ActiveModel::Model

  def self.file_type_counts
    type_counts = {}

    result = Solr::Query.new(
               'has_model_ssim:"DRI::DigitalObject"',
               100,
               { facet: true,
                 'facet.field' => 'file_type_display_sim' }
             ).get

    facet = result['facet_counts']['facet_fields']['file_type_display_sim']
    facet.each_slice(2) do |type,count|
      next unless %w(image video audio text).include?(type)
      type_counts[type] = count
    end

    type_counts
  end

  def self.mime_type_counts
    type_counts = {}

    result = Solr::Query.new(
               'has_model_ssim:"DRI::DigitalObject"',
               100, { facet: true, 'facet.field' => 'mime_type_sim' }
             ).get

    facet = result['facet_counts']['facet_fields']['mime_type_sim']
    facet.each_slice(2) do |type,count|
      next if count == 0
      type_counts[type] = count
    end

    type_counts
  end

  def self.summary
    total_objects = Solr::Query.new('has_model_ssim:"DRI::DigitalObject" and is_collection_sim:false').count
    total_assets = Solr::Query.new('has_model_ssim:"DRI::GenericFile"').count

    {total_objects: total_objects, total_assets: total_assets}
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
