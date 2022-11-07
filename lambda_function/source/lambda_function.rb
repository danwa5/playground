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
    year_data = [
      ['Date', 'Opponent', '3FGA', '3FGM']
    ]

    desired_col_indexes = []

    table.search('tr').each_with_index do |tr, row_index|
      cells = tr.search('th, td').map { |cell| cell.text.strip }

      if row_index.zero?
        cells.each_with_index do |cell, col_index|
          desired_col_indexes << col_index if cell.match?(/(date|opponent|3fgm|3fga)/i)
        end
      else
        game_data = []

        desired_col_indexes.each do |i|
          game_data << cells[i]
        end

        year_data << game_data
      end
    end

    year_data
  end
end
