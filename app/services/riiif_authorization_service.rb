class RiiifAuthorizationService

  def initialize(controller)
    @controller = controller
  end

  def can?(action, object)
    id = object.id

    resp = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
    file_doc = resp.first
    resp = ActiveFedora::SolrService.query("id:#{file_doc['isPartOf_ssim'].first}", 
      defType: 'edismax', rows: '1')
    object_doc = resp.first

    if action == :show
      @controller.can?(:show_digital_object, object_doc['id']) && @controller.can?(:read, object_doc['id'])
    elsif action == :info
      @controller.can?(:show_digital_object, object_doc['id'])
    end
  end

  end