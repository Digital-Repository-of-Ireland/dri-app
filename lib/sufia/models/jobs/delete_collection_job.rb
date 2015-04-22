require 'doi/doi'
require 'utils'

class DeleteCollectionJob < ActiveFedoraPidBasedJob

  def queue_name
    :delete_collection
  end

  def run
    Rails.logger.info "Deleting all objects in #{object.id}"
    
    o = ActiveFedora::Base.find(object.id, {:cast => true})

    o.governed_items.each do | curr_object |
      
      # If object is a collection and has sub-collections, apply to governed_items
      if curr_object.is_collection?
        unless (curr_object.governed_items.nil? || curr_object.governed_items.empty?)
          Sufia.queue.push(DeleteCollectionJob.new(curr_object.id))
        else
          curr_object.delete
        end
      else
        begin
          # this makes a connection to s3, should really test if connection is available somewhere else
          delete_files(curr_object)
        rescue Exception => e
          Rails.logger.error "Unable to delete files: #{e}"
        end
        
        curr_object.generic_files.each do |gf|
          gf.delete
        end
        
        curr_object.delete
      end
    end
  
    # Delete collection
    object.reload
    object.delete
  end

  def delete_files(object)
    local_file_info = LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d",
                                      { :f => object.id, :d => 'content' }).order("version DESC").to_a
    local_file_info.each { |file| file.destroy }
    FileUtils.remove_dir(Rails.root.join(Settings.dri.files).join(object.id), :force => true)

    storage = Storage::S3Interface.new
    storage.delete_bucket(object.id)
  end

end
