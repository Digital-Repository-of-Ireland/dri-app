class IndexTextJob < ActiveFedoraIdBasedJob

  def queue_name
    :index_text
  end

  def run
    Rails.logger.info "Creating full text index of #{generic_file_id} asset"

    url = Blacklight.solr_config[:url] ? Blacklight.solr_config[:url] : Blacklight.solr_config["url"] ? Blacklight.solr_config["url"] : Blacklight.solr_config[:fulltext] ? Blacklight.solr_config[:fulltext]["url"] : Blacklight.solr_config[:default]["url"]
    uri = URI("#{url}/update/extract?extractOnly=true&wt=json&extractFormat=text")

    filename = generic_file.path
    content = File.read(filename)
    req = Net::HTTP.new(uri.host, uri.port)
    resp = req.post(uri.to_s, content, {
          'Content-type' => "#{generic_file.mime_type};charset=utf-8",
          'Content-Length' => content.size.to_s
        })
    raise "URL '#{uri}' returned code #{resp.code}" unless resp.code == "200"
    extracted_text = JSON.parse(resp.body)[''].rstrip
    generic_file.full_text.content = extracted_text if extracted_text.present?
    generic_file.save

    if extracted_text.present?
      if generic_file.digital_object.full_text.empty?
        generic_file.digital_object.full_text = [extracted_text]
      else
        generic_file.digital_object.full_text = generic_file.batch.full_text.push(extracted_text)
      end
      generic_file.digital_object.save    
    end

  rescue => e
    Rails.logger.error("Error extracting content from #{self.pid}: #{e.inspect}")
  end 

end

