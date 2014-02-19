class PdfSurrogateJob < ActiveFedoraPidBasedJob

  def queue_name
    :pdf
  end

  def run
    Rails.logger.info "Creating pdf surrogate of #{generic_file_id} asset"

    local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE 'content'",
                                                             { :f => generic_file_id } ],
                                      :order => "version DESC",
                                      :limit => 1)
    filename = local_file_info.first.path

    bucket_id = object.batch.nil? ? object.pid : object.batch.pid
    surrogate_filename = "#{generic_file_id}_pdf.pdf"

    out_file = File.open(filename, "rb")

    storage = Storage::S3Interface.new
    storage.store_surrogate(bucket_id, out_file, surrogate_filename)
    storage.close
    
  end

end
