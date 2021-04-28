class RiiifAuthorizationService

  def initialize(controller)
    @controller = controller
  end

  def can?(action, object)
    id = object.alternate_id.split(':')[1]

    file_doc = SolrDocument.find(id)
    return true if file_doc.collection?
    return false unless file_doc && file_doc['isPartOf_ssim'].present?

    object_doc = SolrDocument.find(file_doc['isPartOf_ssim'].first)

    if action == :show
      object_doc.published? && object_doc.public_read?
    elsif action == :info
      object_doc.published?
    end
  end
end
