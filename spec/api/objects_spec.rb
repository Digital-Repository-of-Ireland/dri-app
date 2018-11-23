# # TODO:
## html only
# objects/:id/citation
# objects/:id/history

# # objects/{id}/access
# # /objects/:id/edit
# # /objects/:id                                done
# # /objects/:id/metadata
# # /objects/:id/files/:id
# # /objects/:id/retrieve/:archive
# # /objects/:id/status (not accessible)
# # /get_objects                                done

require 'swagger_helper'

describe 'Objects API' do
  path "/objects/{id}/" do
    get 'retrieves a specific object' do
      tags 'objects'
      include_context 'rswag_user_with_collections', status: 'published'

      parameter name: :id, description: 'Object ID',
          in: :path, :type => :string
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false

      produces 'application/json', 'application/endnote', 'application/zip'
      response '200', 'Found'  do
        context 'Collection' do
          let(:id) { @collections.first.id }
          it_behaves_like 'it has no json licence information', 'licence'
          include_context 'rswag_include_json_spec_output', 'Found Collection' do
            it_behaves_like 'a pretty json response'
          end
        end
        context 'Object' do
          let(:id) { @collections.first.governed_items.first.id }
          include_context 'rswag_include_json_spec_output', 'Found Object' do
            it_behaves_like 'it has json licence information', 'licence'
            it_behaves_like 'it has json doi information', 'doi'
          end
        end
      end
    end
  end
end
