require 'httparty'
require 'nokogiri'
require_relative 'database_service'

def lambda_handler(event:, context:)
  LambdaFunction.new.call(event: event, context: context)
end

class LambdaFunction
  attr_reader :event

  def call(event:, context:)
    @event = event

    page = HTTParty.get(player_game_log_url)
    parsed_page = Nokogiri::HTML(page)
    table = parsed_page.css('.TableBase-table').last

    return false if table.nil?

    player_data = parse_data(table)
    return false if player_data.empty?

    database_service.create_records(player_data)
  end

  private

  def parse_data(table)
    player_data = []
    column_mapping = {}

    table.search('tr').each_with_index do |tr, row_index|
      cells = tr.search('th, td').map { |cell| cell.text.strip }

      if row_index.zero?
        cells.each_with_index do |cell, col_index|
          case cell
          when /date/i then column_mapping['date'] = col_index
          when /opponent/i then column_mapping['opponent'] = col_index
          when /3fga/i then column_mapping['3fga'] = col_index
          when /3fgm/i then column_mapping['3fgm'] = col_index
          end
        end
      else
        game_data = {}

        column_mapping.each do |field, index|
          value = field == 'date' ? Date.parse(cells[index]).to_s : cells[index]
          game_data[field] = value
        end

        player_data << game_data
      end
    end

    player_data.reverse
  end

  def player_name
    event.fetch('player_name')
  rescue
    raise "The 'player_name' key in the event payload is required"
  end

  def player_game_log_mapping
    {
      'steph-curry' => 'https://www.cbssports.com/nba/players/1685204/stephen-curry/game-log/',
      'klay-thompson' => 'https://www.cbssports.com/nba/players/1647559/klay-thompson/game-log/',
      'jordan-poole' => 'https://www.cbssports.com/nba/players/2892690/jordan-poole/game-log/'
    }
  end

  def player_game_log_url
    player_game_log_mapping.fetch(player_name)
  rescue
    raise "Cannot find the game log URL for '#{player_name}'"
  end

  def database_service
    @database_service ||= DatabaseService.new(player_name)
  end
end
