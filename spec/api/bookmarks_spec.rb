require 'swagger_helper'

# TODO deprecate this endpoint?
describe "Bookmarks API" do
  path "/bookmarks" do
    get "retrieves bookmarks" do
      # tags 'Bookmarks'      
      produces "application/json"
      response '302', 'bookmark redirect' do
        include_context 'sign_out_before_request'
        # can't include output since redirect includes html
        # include_context 'rswag_include_json_spec_output'
          
        it 'returns 302 regardless of whether you are signed in' do
          expect(status).to eq 302
        end
      end
    end
  end
end
