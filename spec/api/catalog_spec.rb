require 'swagger_helper'

describe "Catalog API" do
  path "/catalog" do
    get "retrieves published (public) objects, collections, or subcollections" do
      produces 'application/json', 'application/xml', 'application/ttl'
      # add subcollections?
      include_context 'rswag_user_with_collections', status: 'published'
      include_context 'doi_config_exists'

      # TODO move common params between catalog and my_collections into helper for consistency
      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9
      parameter name: :page, description: 'Page number', 
        in: :query, type: :number, default: 1, required: false
      # default: objects if param is omitted, collections if using search through UI
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, type: :string, default: 'objects',
        enum: %w[objects collections]
      # default: false if param is omitted, true if using search through UI
      parameter name: :show_subs, description: 'Show subcollections',
        in: :query, type: :boolean, default: false
      parameter name: :sort, description: 'Solr fields to sort by',
        in: :query, type: :string, default: nil
      parameter name: :search_field, description: 'Search for data in this field only',
        in: :query, type: :string, default: 'all_fields', required: false,
        # keep docs in sync with dev, show all possible valid values for search_field
        enum: CatalogController.blacklight_config.search_fields.keys
      parameter name: :q, description: 'Search Query',
        in: :query, type: :string, required: false

      parameter name: :pretty, description: 'Indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false

      let(:per_page)  { 9 }
      let(:page)      { 1 }
      let(:mode)      { 'objects' }
      let(:show_subs) { false }
      let(:sort)         { nil }

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
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false
      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string
      include_context 'rswag_user_with_collections', status: 'published'
      include_context 'doi_config_exists'

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
