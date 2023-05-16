# curl 'https://<API-ID>.execute-api.us-west-1.amazonaws.com/v1/team-stats/scrape' \
#   -X POST \
#   -H 'Content-Type: application/json' \
#   -H 'Authorization: <AUTH-TOKEN>' \
#   -d '{"game_date":"2022-12-06"}'

require 'dotenv/load'
require 'net/http'
require 'json'
require 'date'

uri = URI("https://#{ENV['AWS_API_ID']}.execute-api.us-west-1.amazonaws.com/v1/team-stats/scrape")
req = Net::HTTP::Post.new(uri)
req.content_type = 'application/json'
req['Authorization'] = ENV['AUTHORIZATION_TOKEN']

req_options = {
  use_ssl: uri.scheme == 'https'
}

date_start = Date.new(2023, 3, 1)
date_end = Date.new(2023, 3, 1)

(date_start .. date_end).each do |date|
  puts "Scraping game data on #{date.to_s}"
  req.body = {
    'game_date' => date.to_s
  }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(req)
  end

  puts response.code
  puts response.body

  break unless response.code.to_s == '200'

  sleep(10)
end
