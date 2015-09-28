class DataciteDoi < ActiveRecord::Base
  scope :ordered, -> { order("created_at DESC") }
  scope :current, -> { ordered.first }
  scope :object_id, -> { pluck(:object_id).uniq }

  has_one :doi_metadata, autosave: true, dependent: :destroy
  delegate :to_xml, to: :doi_metadata
  delegate :metadata_fields, to: :doi_metadata

  before_create :set_version
  before_create :set_metadata

  def object
    object ||= ActiveFedora::Base.find(self.object_id, cast: true)
  end

  def update_metadata(params)
    params.delete_if { |key, value| !self.doi_metadata.metadata_fields.include?(key.to_s) }
    
    parameters = ActionController::Parameters.new(params)
    self.doi_metadata.assign_attributes(parameters.permit!)
    
    set_update_type
  end
 
  def changed?
    self.update_type == "mandatory" || self.update_type == "required"
  end

  def clear_changed
    self.update_type = "none"
  end

  def mandatory_update?
    self.update_type == "mandatory"
  end
      
  def doi
    doi = "DRI.#{self.object_id}"
    doi = "#{doi}-#{self.version}" if self.version && self.version > 0
    File.join(DoiConfig.prefix.to_s, doi)
  end
  
  def set_update_type
    if self.doi_metadata.title_changed? || self.doi_metadata.creator_changed?
      self.update_type = "mandatory"
    elsif self.doi_metadata.changed?
      self.update_type = "required"
    else
      self.update_type = "none"
    end
    
    self.save
  end

  private
    
    def set_version
      self.version = DataciteDoi.where(object_id: self.object_id).count
    end

    def set_metadata
      metadata = DoiMetadata.new
      metadata.title = self.object.title
      metadata.creator = self.object.creator
      metadata.description = self.object.description
      metadata.subject = self.object.subject if self.object.subject
      metadata.creation_date = self.object.creation_date if self.object.creation_date
      metadata.published_date =  self.object.published_date if self.object.published_date
      metadata.rights = self.object.rights if self.object.rights
      metadata.save

      self.doi_metadata = metadata
    end

end
