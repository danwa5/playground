require 'aws-sdk-sns'
require 'httparty'
require 'nokogiri'
require_relative 'event'

def lambda_handler(event:, context:)
  LambdaFunction.new.call(event: event, context: context)
end

class LambdaFunction
  attr_reader :event

  TEAMS = %w(ATL BKN BOS CHA CHI CLE DAL DEN DET GS HOU IND LAC LAL MEM MIA MIL MIN NO NY OKC ORL PHI PHO POR SA SAC TOR UTA WAS).freeze

  def call(event:, context:)
    @event = event
    host = 'https://www.cbssports.com'.freeze

    page = HTTParty.get("https://www.cbssports.com/nba/schedule/#{game_date_formatted}/")
    @parsed_page = Nokogiri::HTML(page)

    games = @parsed_page.css('div#TableBase table.TableBase-table tr.TableBase-bodyTr')
    boxscore_urls = games.css('div.CellGame a').map { |g| host + g['href'] }
    valid_boxscore_urls = find_valid_boxscore_urls(boxscore_urls)

    send_sns(valid_boxscore_urls)
  end

  private

  def send_sns(boxscore_urls)
    results = {}

    boxscore_urls.each do |url|
      result = sns_client.publish(
        topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
        message:   message(url)
      )

      results[url] = result.message_id
    end

    results
  end

  def find_valid_boxscore_urls(urls)
    urls.select do |url|
      matched = url.match(%r{NBA_\d{8}_([A-Z]{2,3})@([A-Z]{2,3})/$})
      TEAMS.include?(matched[1]) && TEAMS.include?(matched[2])
    end
  end

  def game_date
    @game_date ||= Event.new(event).game_date
  end

  def game_date_formatted
    d = Date.parse(game_date)
    d.strftime('%Y%m%d')
  rescue NoMethodError
    raise ClientError, "[BadRequest] The 'game_date' key in the event payload is required"
  rescue Date::Error
    raise ParsingError, "[BadRequest] The 'game_date' key in the event payload is invalid"
  end

  def message(url)
    { "boxscore_url": url }.to_json
  end

  def sns_client
    @sns_client ||= Aws::SNS::Client.new
  end
end

class ClientError < StandardError; end
class ParsingError < StandardError; end
