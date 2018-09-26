# # TODO:
## html only
# objects/:id/citation
# objects/:id/history

# # objects/{id}/access
# # /objects/:id/edit
# # /objects/:id
# # /objects/:id/metadata
# # /objects/:id/files/:id
# # /objects/:id/retrieve/:archive
# # /objects/:id/status (not accessible)
# # /get_objects

# require 'swagger_helper'

# describe 'Objects API' do
#   path '/get_objects' do
#     include_context 'user_with_collections'

#     post 'retrieve all objects' do
#       tags 'Private (Sign in required)'
#       # TODO deprecate this endpoint?
#       produces 'application/json'
#       response '200', 'Found all objects' do
#         run_test!
#       end
#     end
#   end
# end
