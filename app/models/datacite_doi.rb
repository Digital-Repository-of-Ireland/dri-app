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
    object ||= retrieve_object
  end

  def update_metadata(params)
    params = params.select { |key, _value| doi_metadata.metadata_fields.include?(key.to_s) }
    params = ActionController::Parameters.new(params) unless params.kind_of?(ActionController::Parameters)
    doi_metadata.assign_attributes(params.permit!)

    set_update_type
  end

  def changed?
    update_type == 'mandatory' || update_type == 'required'
  end

  def retrieve_object
    ident = DRI::Identifier.find_by(alternate_id: object_id)
    ident.identifiable if ident
  end

  def clear_changed
    self.update_type = 'none'
  end

  def mandatory_update?
    update_type == 'mandatory'
  end

  def minted?
    status == 'minted'
  end

  def doi
    doi = "DRI.#{object_id}"
    doi = "#{doi}-#{version}" if version && version > 0
    File.join(DoiConfig.prefix.to_s, doi)
  end

  # @return [String] url
  def doi_url
    "https://doi.org/#{doi}"
  end

  # representation of doi used in json api
  #
  # @return [Hash] json
  def show
    json = self.as_json(only: [:created_at, :version])
    json['url'] = doi_url
    json
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
        role = Solr::SchemaFields.searchable_string("role_#{r}")
        people << doc[role] if doc.key?(role)
      end

      people.flatten.uniq
    end

    def creator_solr
      doc = solr_document

      key = Solr::SchemaFields.searchable_string('creator')

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
      SolrDocument.find(object_id)
    end

    def set_version
      self.version = DataciteDoi.where(object_id: object_id).count
    end

    def set_metadata
      metadata = DoiMetadata.new
      metadata.title = object.title.to_a if object.title.present?
      metadata.creator = find_creator.reject(&:blank?)
      metadata.description = object.description.reject(&:blank?) if object.description.present?
      metadata.subject = object.subject.reject(&:blank?) if object.subject.present?
      metadata.creation_date = object.creation_date.to_a if object.respond_to?(:creation_date) && object.creation_date.present?
      metadata.published_date = object.published_date.to_a if object.respond_to?(:published_date) && object.published_date.present?
      metadata.rights = object.rights.to_a if object.rights
      metadata.resource_type = object.type.to_a
      metadata.save

      self.doi_metadata = metadata
    end
end
