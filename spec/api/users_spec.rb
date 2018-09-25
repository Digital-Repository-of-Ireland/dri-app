require 'swagger_helper'

describe 'Users API' do
  path '/users/sign_out' do
    include_context 'collection_manager_user'
    delete 'Signs the current user out' do
      tags 'users'
      produces 'nothing'

      # should redirect to sign in
      response '204', 'Returns no content, only manages the state of the session' do
        run_test!
      end
    end
  end
  path '/users/sign_in' do
    post 'Signs the user in' do
      tags 'users'
      consumes 'multipart/form-data'
      # TODO find proper way to set output to nothing
      # or produce some json response

      parameter name: 'user[email]', in: :formData, type: :string
      parameter name: 'user[password]', in: :formData, type: :string
      
        let('user[email]') { nil }
      let('user[password]') { nil }

      # response '401', 'Invalid credentials' do
      #   run_test!
      # end
      
      response '200', 'Valid credentials' do
        let('user[email]') { 'admin@dri.ie' }
        let('user[password]') { 'CHANGEME' }
        run_test!
      end
    end
  end
end
