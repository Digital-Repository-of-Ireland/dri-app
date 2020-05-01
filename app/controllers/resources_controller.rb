class ResourcesController < ApplicationController

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  def show
    provider = DRI::Sparql::Provider::Sparql.new
    provider.endpoint = AuthoritiesConfig['data.dri.ie']['endpoint']

    @triples = provider.retrieve_data(["https://repository.dri.ie/resource/#{params[:object]}", nil, nil])

    respond_to do |format|
      format.ttl { render plain: ttl }
      format.rdf { render plain: rdf }
    end

  end

  private

  def ttl
    output = RDF::Writer.for(:ntriples).buffer do |writer|
      @triples.each { |triple| writer << triple }
    end

    output
  end

  def rdf
    output = RDF::RDFXML::Writer.buffer do |writer|
      @triples.each { |triple| writer << triple }
    end

    output
  end
end
