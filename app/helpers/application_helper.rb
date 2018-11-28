module ApplicationHelper
  require 'storage/s3_interface'
  require 'uri'

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?
  end

  def iiif_info_url(doc_id, file_id)
    "#{Settings.iiif.server}/#{doc_id}:#{file_id}/info.json"
  end

  def root?
    request.env['PATH_INFO'] == '/' && request.path.nil? && request.query_string.blank?
  end

  def has_browse_params?
    has_search_parameters? || params[:mode].present? || params[:search_field].present? || params[:view].present?
  end

  def has_search_parameters?
    params[:q].present? || params[:f].present? || params[:search_field].present?
  end

  # URI Checker
  def uri?(string)
    uri = URI.parse(string)
    %w(http https).include?(uri.scheme)
  rescue URI::BadURIError, URI::InvalidURIError
    false
  end
end
