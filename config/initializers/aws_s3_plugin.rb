Aws::S3::Plugins::Endpoints::Handler.class_eval do
  def call(context)
    # If endpoint was discovered, do not resolve or apply the endpoint.
    unless context[:discovered_endpoint]
      params = parameters_for_operation(context)
      endpoint = context.config.endpoint_provider.resolve_endpoint(params)

      context.http_request.endpoint = endpoint.url
      apply_endpoint_headers(context, endpoint.headers)
    end

    context[:endpoint_params] = params
    context[:auth_scheme] =
      context.config.signature_version || Aws::Endpoints.resolve_auth_scheme(context, endpoint)

    @handler.call(context)
  end
end

