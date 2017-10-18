class CreateExportJob
  require 'csv'

  @queue = :create_archive

  def self.perform(object_id, fields, email)
    @first_pass = Tempfile.new("#{object_id}_export_first")
    
    assets = fields.delete('assets')
    options = { fields: fields.keys }
    
    @max_headers = {}

    titles = ['Id'].concat(fields.values)
    titles << 'Licence'
    if assets.present?
      options[:with_assets] = true
      titles << 'Assets'
    end
    titles << 'Url'

    first_pass(object_id, titles, options)
    output = second_pass(object_id, titles)
    
    key = store_export(object_id, email, output.path)
    @first_pass.unlink
    output.unlink
    JobMailer.export_ready_mail(key, email, object_id).deliver_now
  end

  def self.first_pass(object_id, titles, options)
    q_result = collection_objects(object_id)

    CSV.open(@first_pass.path, "wb") do |csv|
      csv << titles # title row

      q_result.each do |doc|
        formatter = DRI::Formatters::Csv.new(doc, options)
        csv_string = formatter.format
        CSV.parse(csv_string, headers: true) do |row|
          row.each do |header, value|
            current_max = @max_headers[header].presence || 0
            value_count = value.nil? ? 0 : value.split('|').count
            @max_headers[header] = value_count if value_count >= current_max
          end
          csv << row
        end
      end
    end
  end

  def self.collection_objects(object_id)
    collection = SolrDocument.new(ActiveFedora::SolrService.query("id:#{object_id}").first)
    search_key = collection.root_collection? ? 'root_collection_id' : 'ancestor_id'

    solr_query = "#{ActiveFedora.index_field_mapper.solr_name(search_key, :facetable, type: :string)}:\"#{object_id}\""
    f_query = "-#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true"

    Solr::Query.new(solr_query, 500, fq: f_query)
  end

  def self.second_pass(object_id, titles)
    # second pass
    output = Tempfile.new("#{object_id}_export")
    CSV.open(output.path, "wb") do |csv|
      csv << headers(titles)

      CSV.foreach(@first_pass.path, headers: true) do |row|
        output_row = []
      
        row.each do |header,value|
          if value.present?
            split_col = value.split('|')
            output_row.push(*split_col)
          end
          start = split_col.present? ? split_col.count : 0
          (start..@max_headers[header]-1).each { |i| output_row << '' }
        end

        csv << output_row
      end
    end

    output
  end

  def self.headers(titles)
    headers = []
    titles.each do |title|
      (@max_headers[title]).times do |i| 
        header = i == 0 ? "#{title}" : "#{title}_#{i}"
        headers << header 
      end
    end

    headers
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