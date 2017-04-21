class CreateExportJob
  require 'csv'

  @queue = :create_archive

  def self.perform(object_id, fields, email)
    tmp = Tempfile.new("#{object_id}_export")
    
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('root_collection_id', :facetable, type: :string)}:\"#{object_id}\""
    f_query = "-#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"

    q_result = Solr::Query.new(solr_query, 500, fq: f_query)
    
    assets = fields.delete('assets')
    options = { fields: fields.keys }
    
    CSV.open(tmp.path, "wb") do |csv|
      titles = ['Id'].concat(fields.values)
      titles << 'Licence'
      if assets.present?
        options[:with_assets] = true
        titles << 'Assets'
      end
      csv << titles # title row

      q_result.each_solr_document do |doc|
        formatter = DRI::Formatters::Csv.new(doc, options)
        csv_string = formatter.format
        rows = CSV.parse(csv_string)
        row = rows[1]
        csv << row
      end
    end

    key = store_export(object_id, email, tmp.path)
    tmp.unlink
    JobMailer.export_ready_mail(key, email, object_id).deliver_now
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