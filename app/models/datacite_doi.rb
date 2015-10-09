class DataciteDoi < ActiveRecord::Base
  scope :ordered, -> { order('created_at DESC') }
  scope :current, -> { ordered.first }
  scope :object_id, -> { pluck(:object_id).uniq }

  has_one :doi_metadata, autosave: true, dependent: :destroy
  delegate :to_xml, to: :doi_metadata
  delegate :metadata_fields, to: :doi_metadata

  before_create :set_version
  before_create :set_metadata

  def object
    object ||= ActiveFedora::Base.find(object_id, cast: true)
  end

  def update_metadata(params)
    params.delete_if { |key, _value| !doi_metadata.metadata_fields.include?(key.to_s) }

    parameters = ActionController::Parameters.new(params)
    doi_metadata.assign_attributes(parameters.permit!)
    
    set_update_type
  end
 
  def changed?
    update_type == 'mandatory' || update_type == 'required'
  end

  def clear_changed
    self.update_type = 'none'
  end

  def mandatory_update?
    update_type == 'mandatory'
  end
      
  def doi
    doi = "DRI.#{object_id}"
    doi = "#{doi}-#{version}" if version && version > 0
    File.join(DoiConfig.prefix.to_s, doi)
  end
  
  def set_update_type
    if doi_metadata.title_changed? || doi_metadata.creator_changed?
      self.update_type = 'mandatory'
    elsif doi_metadata.changed?
      self.update_type = 'required'
    else
      self.update_type = 'none'
    end
    
    save
  end

  private
    
    def set_version
      self.version = DataciteDoi.where(object_id: object_id).count
    end

    def set_metadata
      metadata = DoiMetadata.new
      metadata.title = object.title
      metadata.creator = object.creator
      metadata.description = object.description
      metadata.subject = object.subject if object.subject
      metadata.creation_date = object.creation_date if object.creation_date
      metadata.published_date = object.published_date if object.published_date
      metadata.rights = object.rights if object.rights
      metadata.save

      self.doi_metadata = metadata
    end

end
