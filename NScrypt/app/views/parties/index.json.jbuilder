json.array!(@parties) do |party|
  json.extract! party, :id, :user_id, :code_id, :role_id, :state
  json.url party_url(party, format: :json)
end
