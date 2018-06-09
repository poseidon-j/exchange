def jwt_headers(user_id: nil, partner_ids: [])
  payload_data = { id: user_id, partner_ids: [partner_id] }
  token = JWT.encode(
    payload_data,
    Rails.application.config_for(:jwt)['hmac_secret'],
    Rails.application.config_for(:jwt)['alg']
  )
  { 'Authorization' => "Bearer: #{token}" }
end