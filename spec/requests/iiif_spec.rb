require 'rails_helper'
require 'swagger_helper'
require 'ostruct'

describe IiifController, type: :request do
  include_context 'rswag_user_with_collections',
    status: 'published', num_collections: 1, num_objects: 2,
    subcollection: false, doi: false, docs: false, object_type: :image do
    before(:each) do
      # don't use example.com, really make the request to the local server
      host! 'localhost'
      sign_in @example_user

      # set up fake image for iiif_viewable#create_canvas
      HEIGHT_SOLR_FIELD = 'height_isi'
      WIDTH_SOLR_FIELD = 'width_isi'
      LABEL_SOLR_FIELD = Solrizer.solr_name('label')

      allow_any_instance_of(
        DRI::IIIFViewable
      ).to receive(:attached_images) do |arg|
        id =  arg.is_a?(String) ? "#{arg}_image1" : "image1"
        [
          OpenStruct.new(
            "#{WIDTH_SOLR_FIELD}": 100,
            "#{HEIGHT_SOLR_FIELD}": 100,
            id: id,
            "#{LABEL_SOLR_FIELD}": ['test_image']
          )
        ]
      end

      allow_any_instance_of(
        DRI::Solr::Document::File
      ).to receive(:file_types).and_return(['image'])
    end
    it 'should put all published images in the collection in a sequence' do
      # get :sequence, id: @collections.first .id, format: :json
      get "/iiif/#{@collections.first.alternate_id}/sequence", params: { format: :json }
      sequences = JSON.parse(response.body)['sequences']
      image_ids = sequences.map do |seq|
        seq['canvases'].map do |canvas|
          canvas['images'].map do |image|
            image_url = image['resource']['service']['@id']
            # get id, between /images/ and :
            # e.g http://localhost:3000/images/j9602061v:zp38wc62h
            image_url[/\/images\/(.*)\:/m, 1]
          end
        end
      end.flatten
      expect(image_ids.sort).to eq(@collections.first.governed_items.map(&:alternate_id).sort)
    end
  end
end
