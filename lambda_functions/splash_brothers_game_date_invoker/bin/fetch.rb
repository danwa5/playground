require 'dotenv/load'
require 'httparty'

team = 'GS'
date = '2023-03-01'

response = HTTParty.get("https://#{ENV['AWS_API_ID']}.execute-api.us-west-1.amazonaws.com/v1/team-stats/#{team}?date=#{date}", :headers => {
  "Content-Type" => "application/json"
})

puts "TEAM: #{team}"
puts "DATE: #{date}"

puts response.code
puts response.body
