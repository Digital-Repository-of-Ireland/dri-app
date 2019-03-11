require 'swagger_helper'

describe "Get Objects API" do
  path "/get_objects" do
    # use post since list of objects could be very large and get request has smaller size limit
    # however, must use named value pairs to exceed url length limit, which this example does not
    post "retrieves objects by id" do
      include_context 'rswag_user_with_collections', status: 'published'
      include_context 'doi_config_exists'
      
      produces 'application/json'
      consumes 'application/json'
      tags 'objects'
      security [ apiKey: [], appId: [] ]

      parameter name: :objects, description: 'array of hashes with object ids as values. e.g. {"objects": [{"v": "zp38wc65b"}]}. Only the first value of each hash is read.',
        in: :body, schema: {
          type: :array,
          items: { type: :object },
          example: {"objects": [{"v": "zp38wc65b"}]}
        }
      pretty_json_param


      response "401", "Must be signed in to access this route" do
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:objects) { @collections.map(&:id) }

        it_behaves_like 'a pretty json response'
        include_context 'rswag_include_json_spec_output' do
          it_behaves_like 'a json api 401 error',
            message: "You need to sign in or sign up before continuing."
        end
      end

      response "200", "Objects found" do
        let(:user_token) { @example_user.authentication_token }
        let(:user_email) { CGI.escape(@example_user.to_s) }

        # objects should have licences
        context 'get objects' do
          # refactor, must be a better way to get array of hashes for objects in collections
           # @collections.map {|c| c.governed_items.map {|i| [[i.id, i.id]].to_h} }.flatten
          let(:object_ids) {
            @collections.map do |c| 
              c.governed_items.map do |i| 
                [[i.id, i.id]].to_h
              end
            end.flatten
          }
          let(:objects) { {objects: object_ids} }
          exn = "/get_objects?(object ids)"
          include_context 'rswag_include_json_spec_output', exn do
            it_behaves_like 'a pretty json response'
            run_test! do
              json_response = JSON.parse(response.body)
              json_response.each do |object|
                # get licence (stored at collection level)
                pid = object['pid']
                governing_collection = @collections.select do |c| 
                  c.governed_items.map(&:id).include?(pid)
                end
                licence = Licence.find_by(name: governing_collection.first.licence)
                expect(object['metadata']['licence']).to eq licence.show
              end
            end
          end
        end

        # collections should not have licences
        context 'get collections' do
          # let(:objects) { @collections.map {|c| [[c.id, c.id]].to_h} }
          # # produces {"object"=>{"_json"=>[{"zp38wc65b"=>"zp38wc65b"}}
          # # https://github.com/domaindrivendev/rswag/issues/132
          # let(:objects) { {objects: [{k: @collections.first.id}]} }
          let(:collection_ids) { @collections.map {|c| [[c.id, c.id]].to_h} }
          let(:objects) { {objects: collection_ids} }
          exn = "/get_objects?(collection ids)"
          include_context 'rswag_include_json_spec_output', exn do
            it_behaves_like 'a pretty json response'
          end
        end
      end
    end
  end
end
