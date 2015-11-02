class DatastreamVersionController < CatalogController
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!

  # Renders the metadata XML for a particular version of a datastream.
  #
  #
  def show
    enforce_permissions!('edit', params[:id])

    begin
      @object = retrieve_object!(params[:id])
    rescue ActiveFedora::ObjectNotFoundError
      render xml: { error: 'Not found' }, status: 404
      return
    end

    if @object && @object.attached_files.keys.include?(params[:stream])
      begin
        data = open("#{ActiveFedora.config.credentials[:url]}/objects/#{@object.id}/datastreams/#{params[:stream]}/content?asOfDateTime=#{params[:date]}")
      rescue OpenURI::HTTPError
        render text: 'Unable to load metadata'
        return
      end
      render xml: data.read
      return
    end

    render text: 'Unable to load metadata'
  end
end
