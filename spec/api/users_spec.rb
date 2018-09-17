require 'swagger_helper'

describe 'Users API' do
  path '/users/sign_out' do
    include_context 'collection_manager_user'
    delete 'Signs the current user out' do
      tags 'Public'
      produces 'nothing'

      # should redirect to sign in
      response '204', 'Returns no content, only manages the state of the session' do
        run_test!
      end
    end
  end
  path '/users/sign_in' do
    post 'Signs in the user' do
      tags 'Public'
      consumes 'multipart/form-data'
      # consumes 'application/x-www-form-urlencoded'

      # parameter name: :user, in: :formData, schema: {
      #   type: :object,
      #   properties: {
      #     email: { type: :string },
      #     password: { type: :string }
      #   },
      #   required: ['email', 'password']
      # }

      # let(:user) { nil }
      parameter name: 'user[email]', in: :formData, type: :string
      parameter name: 'user[password]', in: :formData, type: :string

      let('user[email]') { nil }
      let('user[password]') { nil }

      # response '401', 'Invalid credentials' do
      #   run_test!
      # end

      # # TODO fix form data issue, request workign on postman
      response '200', 'Valid credentials' do
        # require 'byebug'
        # let(:user) { {email: 'admin@dri.ie', password: 'CHANGEME'} }
        let('user[email]') { 'tadmin@dri.ie' }
        let('user[password]') { 'CHANGEME' }
        run_test!
      end
    end
  end
end
