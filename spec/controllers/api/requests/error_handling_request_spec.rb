require 'rails_helper'

describe Api::GraphqlController, type: :request do
  describe 'ErrorType' do
    let(:auth_headers) { jwt_headers(user_id: 'user-id', partner_ids: ['p1'], roles: nil) }
    let(:mutation_input) do
      {
        artworkId: 'test'
      }
    end
    let(:mutation) do
      <<-GRAPHQL
        mutation($input: CreateOrderWithArtworkInput!) {
          createOrderWithArtwork(input: $input) {
            orderOrError {
              ... on OrderWithMutationSuccess {
                order {
                  id
                  buyer {
                    ... on Partner {
                      id
                    }
                  }
                  seller {
                    ... on User {
                      id
                    }
                  }
                }
              }
              ... on OrderWithMutationFailure {
                error {
                  code
                  data
                  type
                }
              }
            }
          }
        }
      GRAPHQL
    end

    context 'StandardError' do
      before do
        allow(CreateOrderService).to receive(:with_artwork!).and_raise('something went wrong')
        post '/api/graphql', params: { query: mutation, variables: { input: mutation_input } }, headers: auth_headers
      end
      it 'returns 500' do
        expect(response.status).to eq 500
      end
      it 'returns formatted the error' do
        result = JSON.parse(response.body)
        expect(result['errors']).not_to be_nil
        error = result['errors'].first
        expect(error['type']).to eq 'internal'
        expect(error['code']).to eq 'generic'
        expect(error['data']['message']).to eq 'something went wrong'
      end
    end

    context 'ActiveRecord::RecordNotFound' do
      before do
        allow(CreateOrderService).to receive(:with_artwork!).and_raise(ActiveRecord::RecordNotFound, 'cannot find')
        post '/api/graphql', params: { query: mutation, variables: { input: mutation_input } }, headers: auth_headers
      end
      it 'returns 404' do
        expect(response.status).to eq 404
      end
      it 'returns formatted the error' do
        result = JSON.parse(response.body)
        expect(result['errors']).not_to be_nil
        error = result['errors'].first
        expect(error['type']).to eq 'validation'
        expect(error['code']).to eq 'not_found'
        expect(error['data']['message']).to eq 'cannot find'
      end
    end

    context 'ActionController::ParameterMissing' do
      before do
        allow(CreateOrderService).to receive(:with_artwork!).and_raise(ActionController::ParameterMissing, 'id')
        post '/api/graphql', params: { query: mutation, variables: { input: mutation_input } }, headers: auth_headers
      end
      it 'returns 400' do
        expect(response.status).to eq 400
      end
      it 'returns formatted the error' do
        result = JSON.parse(response.body)
        expect(result['errors']).not_to be_nil
        error = result['errors'].first
        expect(error['type']).to eq 'validation'
        expect(error['code']).to eq 'missing_param'
        expect(error['data']['field']).to eq 'id'
      end
    end
  end
end