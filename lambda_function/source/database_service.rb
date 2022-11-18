require 'aws-sdk-dynamodb'

class DatabaseService
  attr_reader :player_name

  def initialize(player_name)
    @player_name = player_name
  end

  def create_records(player_data)
    return false if player_data.empty?

    games = player_data.select { |g| !existing_records.include?(g['date']) }
    return false if games.empty?

    records_created = 0

    games.each do |game|
      records_created += create_record(game)
    end

    "#{player_name}: created #{records_created} record(s)."
  end

  private

  def create_record(game)
    resp = dynamodb_client.put_item(
      table_name: dynamodb_table_name,
      item: {
        'player_name' => player_name,
        'game_date' => game['date'],
        'opponent' => game['opponent'],
        'fg3a' => game['3fga'].to_i,
        'fg3m' => game['3fgm'].to_i
      }
    )

    1
  rescue
    0
  end

  def existing_records
    @existing_records ||= begin
      resp = dynamodb_client.query(
        table_name: dynamodb_table_name,
        key_condition_expression: "player_name = :player_name",
        expression_attribute_values: {
          ":player_name" => player_name
        },
        projection_expression: 'game_date'
      )

      if resp.items.empty?
        []
      else
        resp.items.map { |i| i['game_date'] }
      end
    end
  end

  def dynamodb_table_name
    'splash-brothers-stats'.freeze
  end

  def dynamodb_client
    @dynamodb_client ||= Aws::DynamoDB::Client.new
  end
end
