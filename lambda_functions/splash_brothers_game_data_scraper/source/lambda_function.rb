require 'httparty'
require 'nokogiri'
require_relative 'database_service'
require_relative 'event'

def lambda_handler(event:, context:)
  LambdaFunction.new.call(event: event, context: context)
end

class LambdaFunction
  attr_reader :event

  def call(event:, context:)
    @event = event

    page = HTTParty.get(boxscore_url)
    @parsed_page = Nokogiri::HTML(page)
    raise ParsingError, "[InternalServerError] Problem finding box score data" if missing_data?

    boxscore_data = []

    away_players.each do |row|
      boxscore_data << parse_player_row(row, false)
    end

    home_players.each do |row|
      boxscore_data << parse_player_row(row, true)
    end

    database_service.create_records(boxscore_data)
  end

  private

  def missing_data?
    game_date.nil? || away_players.empty? || home_players.empty? || away_team.nil? || home_team.nil? || player_row_index.nil? || fg3_row_index.nil?
  end

  def away_players
    away_starter_data = @parsed_page.css('div#player-stats-away div.starters-stats div.stats-viewable-area table.stats-table tr.data-row')
    away_bench_data = @parsed_page.css('div#player-stats-away div.bench-stats div.stats-viewable-area table.stats-table tr.data-row')

    [away_starter_data, away_bench_data].flatten
  end

  def home_players
    home_starter_data = @parsed_page.css('div#player-stats-home div.starters-stats div.stats-viewable-area table.stats-table tr.data-row')
    home_bench_data = @parsed_page.css('div#player-stats-home div.bench-stats div.stats-viewable-area table.stats-table tr.data-row')

    [home_starter_data, home_bench_data].flatten
  end

  def away_team
    @away_team ||= @parsed_page.css('div.team-name-container.away .abbr').text.strip
  end

  def home_team
    @home_team ||= @parsed_page.css('div.team-name-container.home .abbr').text.strip
  end

  def headers
    @headers ||= begin
      @parsed_page.css('div#player-stats-away div.starters-stats div.stats-viewable-area table.stats-table tr.header-row td')
                  .map { |td| td.text }
    end
  end

  def player_row_index
    @player_row_index ||= headers.index { |x| x =~ /(starters|bench)/i }
  end

  def fg3_row_index
    @fg3_row_index ||= headers.index { |x| x == '3PT' }
  end

  def parse_player_row(row, at_home)
    fg3_data = row.css('td')[fg3_row_index].text.strip
    fg3m, fg3a = fg3_data.split('/').map(&:to_i) if fg3_data =~ %r{\d+/\d+}

    name_cell = row.css('td')[player_row_index]
    player_link = name_cell.css('a')[0]['href']
    player_name = name_cell.text.strip
    matched = player_link.match(%r{https://www.cbssports.com/nba/players/(\d+)/.+/})

    {
      'team' => at_home ? home_team : away_team,
      'player_id' => matched[1],
      'player_name' => player_name,
      'game_date' => game_date,
      'opponent' => at_home ? away_team : home_team,
      'at_home' => at_home,
      'fg3m' => fg3m,
      'fg3a' => fg3a,
    }
  end

  def game_date
    if matched = boxscore_url.match(%r{https://www.cbssports.com/nba/gametracker/(recap|boxscore)/NBA_(\d{8})_.+/})
      Date.parse(matched[2]).to_s
    end
  end

  def boxscore_url
    @boxscore_url ||= Event.new(event).boxscore_url
  rescue
    raise ClientError, "[BadRequest] The 'boxscore_url' key in the event payload is required"
  end

  def database_service
    @database_service ||= DatabaseService.new
  end
end

class ClientError < StandardError; end
class ParsingError < StandardError; end
