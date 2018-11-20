require 'swagger_helper'

describe "Get Objects API" do
  path "/get_objects" do
    post "retrieves objects by id" do
      security [ apiKey: [], appId: [] ]
      produces 'application/json'
      parameter name: :objects, description: 'array of object ids',
        in: :query, type: :array, required: true
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false

      include_context 'rswag_user_with_collections', status: 'published'

      # response "401", "Must be signed in to access this route" do
      #   let(:user_token) { nil }
      #   let(:user_email) { nil }
      #   let(:objects) { @collections.map(&:id) }

      #   include_context 'rswag_include_json_spec_output' do
      #     it_behaves_like 'a json api error'
      #     it_behaves_like 'a json api 401 error',
      #       message: "You need to sign in or sign up before continuing."
      #     it_behaves_like 'a pretty json response'
      #   end
      # end

      response "200", "Objects found" do
        let(:user_token) { @example_user.authentication_token }
        let(:user_email) { CGI.escape(@example_user.to_s) }
        let(:objects) { @collections.map(&:id) }
        include_context 'rswag_include_json_spec_output' do
          it_behaves_like 'a pretty json response'
        end
      end
    end
  end
end
