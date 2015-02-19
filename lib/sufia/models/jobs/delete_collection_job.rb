require 'doi/doi'
require 'utils'

class DeleteCollectionJob < ActiveFedoraPidBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.id}"

    query = Solr::Query.new("#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\"")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {:cast => true})
        begin
          # this makes a connection to s3, should really test if connection is available somewhere else
          delete_files(o)
        rescue Exception => e
          Rails.logger.error "Unable to delete files: #{e}"
        end
        
        o.generic_files.each do |gf|
          gf.delete
        end
        o.delete
      end

      object.reload
      object.delete
    end

  end

  def delete_files(object)
    local_file_info = LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d",
                                      { :f => object.id, :d => 'content' }).order("version DESC").to_a
    local_file_info.each { |file| file.destroy }
    FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(object.id), :force => true)

    storage = Storage::S3Interface.new
    storage.delete_bucket(Utils.split_id(object.id))
  end

end
