require 'google/api_client'
require 'date'

service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT']
key_content = ENV['GOOGLE_KEY_CONTENT']
key_secret = 'notasecret'
profile_id = ENV['GOOGLE_ANALYTICS_PROFILE']

client = Google::APIClient.new(application_name: 'Dashing Widget',
                               application_version: '0.01')

key = OpenSSL::PKey::RSA.new key_content, key_secret

client.authorization = Signet::OAuth2::Client.new(
  token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
  audience: 'https://accounts.google.com/o/oauth2/token',
  scope: 'https://www.googleapis.com/auth/analytics.readonly',
  issuer: service_account_email,
  signing_key: key)

SCHEDULER.every '1m', first_in: 0 do

  client.authorization.fetch_access_token!
  analytics = client.discovered_api('analytics', 'v3')
  start_date = (DateTime.now - 7).strftime('%Y-%m-%d') # one week ago
  end_date = DateTime.now.strftime('%Y-%m-%d')  # now

  visit_count = client.execute(api_method: analytics.data.ga.get, parameters: {
    'ids' => 'ga:' + profile_id,
    'start-date' => start_date,
    'end-date' => end_date,
    'dimensions' => 'ga:year,ga:month,ga:day',
    'metrics' => 'ga:visitors',
  })

  points = []
  visit_count.data.rows.each do |data|
    year, month, day, visitors = *data.map(&:to_i)

    timestamp = Time.new(year, month, day).to_i
    points << { x: timestamp, y: visitors }
  end

  points.pop
  send_event('visitor_count',  points: points)
end
