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
    self.update_type = if doi_metadata.title_changed? || doi_metadata.creator_changed?
                         'mandatory'
                       elsif doi_metadata.changed?
                         'required'
                       else
                         'none'
                       end

    save
  end

  private

    def creator_relators
      doc = solr_document

      people = []
      DRI::Vocabulary.marc_relators.each do |r|
        role = ActiveFedora.index_field_mapper.solr_name("role_#{r}", :stored_searchable, type: :string)
        people << doc[role] if doc.key?(role)
      end

      people.flatten.uniq
    end

    def creator_solr
      doc = solr_document

      key = ActiveFedora.index_field_mapper.solr_name('creator', :stored_searchable, type: :string)

      doc.key?(key) ? doc[key] : nil
    end

    def find_creator
      return object.creator if object.creator.present?

      creator = creator_solr
      return creator if creator.present?

      return object.author if object.respond_to?(:author) && object.author.present?

      creator = creator_relators
      return creator if creator.present?
    end

    def solr_document
      result = ActiveFedora::SolrService.query("id:#{object_id}")
      SolrDocument.new(result.first)
    end

    def set_version
      self.version = DataciteDoi.where(object_id: object_id).count
    end

    def set_metadata
      metadata = DoiMetadata.new
      metadata.title = object.title if object.title.present?
      metadata.creator = find_creator
      metadata.description = object.description if object.description.present?
      metadata.subject = object.subject if object.subject.present?
      metadata.creation_date = object.creation_date if object.creation_date.present?
      metadata.published_date = object.published_date if object.published_date.present?
      metadata.rights = object.rights if object.rights
      metadata.save

      self.doi_metadata = metadata
    end
end
