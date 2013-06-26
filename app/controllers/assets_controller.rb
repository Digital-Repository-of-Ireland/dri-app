# Base controller for the asset managing controllers.
#
class AssetsController < CatalogController
  require 'checksum'

  include Hydra::AccessControlsEnforcement
  include DRI::Metadata
  include DRI::Model
  #Moved from application controller due to routing issues with devise
  include Blacklight::Catalog

  # Retrieves a Fedora Digital Object by ID
  def retrieve_object(id)
    return objs = ActiveFedora::Base.find(id,{:cast => true})
  end

  def retrieve_object!(id)
    objs = ActiveFedora::Base.find(id,{:cast => true})
    raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') +" ID: #{id}" if objs.nil?
    return objs
  end

  def check_for_duplicates(object)
      @duplicates = duplicates(object)

      if @duplicates && !@duplicates.empty?
        warning = t('dri.flash.notice.duplicate_object_ingested', :duplicates => @duplicates.map { |o| "'" + o.id + "'" }.join(", ").html_safe)
        flash[:alert] = warning
        @warnings = warning 
      end
  end

  private

  def duplicates(object)
    if object.governing_collection && !object.governing_collection.nil?
      ActiveFedora::Base.find(:is_governed_by_ssim => "info:fedora/#{object.governing_collection.id}", :metadata_md5_tesim => object.metadata_md5).delete_if{|obj| obj.id == object.pid}
    end
  end

end
