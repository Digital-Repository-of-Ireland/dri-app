class Report
  include ActiveModel::Model

  def self.mime_type_counts
    type_counts = {}

    result = ActiveFedora::SolrService.get('*:*', facet: true, 'facet.field' => 'mime_type_sim')
    facet = result['facet_counts']['facet_fields']['mime_type_sim']
    facet.each_cons(2) { |type,count| type_counts[type] = count }
  
    type_counts
  end
end
