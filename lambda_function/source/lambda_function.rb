require 'httparty'
require 'nokogiri'
require 'byebug'

def lambda_handler(event:, context:)
  LambdaFunction.new.call(event: event, context: context)
end

class LambdaFunction
  def call(event:, context:)
    url = 'https://www.cbssports.com/nba/players/1685204/stephen-curry/game-log/'
    page = HTTParty.get(url)
    parsed_page = Nokogiri::HTML(page)
    table = parsed_page.css('.TableBase-table').last

    return false if table.nil?

    parse_data(table)
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
          game_data[field] = cells[index]
        end

        player_data << game_data
      end
    end

    player_data
  end
end
