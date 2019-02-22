require 'swagger_helper'

describe "Catalog API" do
  path "/catalog" do
    get "retrieves objects from the catalog" do
      produces 'application/json', 'application/xml', 'application/ttl'
      # add subcollections?
      include_context 'rswag_user_with_collections', status: 'published'
      include_context 'doi_config_exists'

      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, type: :string, default: 'objects'
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false
      parameter name: :search_field, description: 'solr field for query q',
        in: :query, type: :string, default: 'all_fields', required: false,
        # keep docs in sync with dev, show all possible valid values for search_field
        enum: CatalogController.blacklight_config.search_fields.keys
      parameter name: :q, description: 'query for search_field',
        in: :query, type: :string, required: false

      let(:per_page) { 9 }
      let(:mode)     { 'objects' }

      response '200', 'catalog found' do
        include_context 'sign_out_before_request' do
          include_context 'rswag_include_json_spec_output' do
            it_behaves_like 'a pretty json response'
          end
        end
        # no output for these specs, just ensure no duplicates are found
        context 'search_field no output' do
          # for searches with each remaining search_field
          fields_hash = CatalogController.blacklight_config.search_fields
          fields_to_test = fields_hash.keys.reject do |field|
            # exclude aggregate fields
             %w[all_fields person].include?(field)
          end.sort

          fields_to_test.each do |field|
            context "#{field} search" do
              include_context 'catch search false positives', field, fields_to_test do
                it_behaves_like 'a search response with no false positives', field
              end
            end
          end
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
