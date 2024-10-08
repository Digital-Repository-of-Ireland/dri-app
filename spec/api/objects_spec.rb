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
      include_context 'rswag_user_with_collections', status: 'published'
      include_context 'doi_config_exists'
      produces 'application/json', 'application/endnote', 'application/zip'
      tags 'objects'

      parameter name: :id, description: 'Object ID',
                in: :path, type: :string
      pretty_json_param

      response '200', 'Found'  do
        context 'Collection' do
          let(:id) { @collections.first.alternate_id }
          it_behaves_like 'a pretty json response'
          it_behaves_like 'it has no json licence information', 'licence'
          include_context 'rswag_include_json_spec_output', 'Found Collection' do
            it_behaves_like 'it has json related objects information', 'related_objects'
          end
        end
        context 'Object' do
          let(:id) { @collections.first.governed_items.first.alternate_id }
          it_behaves_like 'it has json licence information', 'licence'
          include_context 'rswag_include_json_spec_output', 'Found Object' do
            it_behaves_like 'it has json doi information', 'doi'
          end
        end
      end
    end
  end
end
