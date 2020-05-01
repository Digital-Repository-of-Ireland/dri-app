require 'swagger_helper'

describe "Catalog API" do
  include_context 'rswag_user_with_collections', status: 'published'
  include_context 'doi_config_exists'

  path "/catalog" do
    get "retrieves published (public) objects, collections, or subcollections" do
      produces 'application/json', 'application/xml', 'application/ttl'

      # helper methods that call rswag parameter methods
      parameter name: :q, description: 'Search Query',
                in: :query, type: :string, required: false
      search_controller_params(CatalogController.blacklight_config)
      default_search_params
      default_page_params
      pretty_json_param

      response '200', 'catalog found' do
        include_context 'sign_out_before_request' do
          include_context 'rswag_include_json_spec_output' do
            it_behaves_like 'a pretty json response'
          end
          # no output for these specs, just ensure no duplicates are found
          it_behaves_like 'it accepts search_field params', CatalogController, :q
        end
      end
    end
  end

  path "/catalog/{id}" do
    get "retrieves a specific object from the catalog" do
      produces 'application/json', 'application/xml', 'application/ttl'

      parameter name: :id, description: 'Object ID',
                in: :path, :type => :string
      pretty_json_param

      response "200", "Found" do
        context 'Collection' do
          let(:id) { @collections.first.id }
          it_behaves_like 'it has no json licence information'
          it_behaves_like 'it has json related objects information'
          include_context 'rswag_include_json_spec_output', 'Found Collection' do
            it_behaves_like 'a pretty json response'
          end
        end
        context 'Object' do
          let(:id) { @collections.first.governed_items.first.id }
          it_behaves_like 'it has json licence information'
          include_context 'rswag_include_json_spec_output', 'Found Object' do
            it_behaves_like 'it has json doi information'
          end
        end
      end
    end
  end
end
