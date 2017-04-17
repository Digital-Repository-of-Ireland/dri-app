class CreateExportJob
  require 'csv'

  @queue = :create_archive

  def self.perform(object_id, fields, email)
    tmp = Tempfile.new("#{object_id}_export")
    puts tmp.path

    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('root_collection_id', :facetable, type: :string)}:\"#{object_id}\""
    f_query = "-#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"

    q_result = Solr::Query.new(solr_query, 500, fq: f_query)
    
    CSV.open(tmp.path, "wb") do |csv|
      titles = ['id'].concat(fields.values)
      titles << 'url'
      csv << titles # title row
      q_result.each_solr_document do |doc| 
        row = []
        row << doc['id']
        fields.keys.each do |key|
          field = doc[ActiveFedora.index_field_mapper.solr_name(key, :stored_searchable, type: :string)]
          value = field.kind_of?(Array) ? field.join(',') : field 
          row << value
        end
        row << Rails.application.routes.url_helpers.url_for(
                 controller: 'catalog', action: 'show', id: doc['id'],
                 protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
               )
        csv << row
      end
    end

    key = store_export(object_id, email, tmp.path)

    JobMailer.export_ready_mail(key, email, object_id).deliver_now
    tmp.unlink
  end

  def self.store_export(object_id, email, csv)
    storage = StorageService.new
    bucket_name = "users.#{Mail::Address.new(email).local}"
    storage.create_bucket(bucket_name) unless storage.bucket_exists?(bucket_name)
    key = "#{object_id}_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"
    storage.store_file(bucket_name, csv, key)
    
    key
  end

end