class RiiifAuthorizationService

  def initialize(controller)
    @controller = controller
  end

  def can?(action, object)
    id = object.noid.split(':')[1]

    resp = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
    file_doc = resp.first
    resp = ActiveFedora::SolrService.query("id:#{file_doc['isPartOf_ssim'].first}", 
      defType: 'edismax', rows: '1')
    object_doc = SolrDocument.new(resp.first)

    if action == :show
      object_doc.published? && object_doc.public_read?
    elsif action == :info
      object_doc.published?
    end
  end

  end