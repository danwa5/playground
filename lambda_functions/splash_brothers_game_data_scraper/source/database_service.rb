require 'aws-sdk-dynamodb'

class DatabaseService
  def create_records(boxscore_data)
    return output_msg if boxscore_data.empty?

    records_created = 0

    boxscore_data.each do |player|
      last_game = find_player_last_game(player)

      # update player's season 3pt totals
      player = update_player_3pt_totals(player, last_game)

      puts "Upserting record for #{player['player_name']}"
      records_created += create_record(player)
    end

    output_msg(records_created)
  end

  private

  def output_msg(record_count = 0)
    "Upserted #{record_count} record(s)"
  end

  def update_player_3pt_totals(player, last_game)
    cumulative_fg3a, cumulative_fg3m = current_3pt_totals(last_game)

    cumulative_fg3a += player['fg3a'] || 0
    cumulative_fg3m += player['fg3m'] || 0

    player.merge(
      'cumulative_fg3a' => cumulative_fg3a,
      'cumulative_fg3m' => cumulative_fg3m
    )
  end

  def current_3pt_totals(game)
    [(game['cumulative_fg3a'] || 0), (game['cumulative_fg3m'] || 0)]
  rescue
    [0, 0]
  end

  def find_player_last_game(player)
    resp = dynamodb_client.query(
      table_name: dynamodb_table_name,
      key_condition_expression: "team = :team",
      filter_expression: "player_id = :player_id",
      expression_attribute_values: {
        ":team" => player['team'],
        ":player_id" => player['player_id'],
      },
      scan_index_forward: false,
      projection_expression: 'game_date_player_uid, player_id, player_name, cumulative_fg3a, cumulative_fg3m'
    )

    resp.items.empty? ? nil : resp.items.first
  end

  def create_record(player)
    resp = dynamodb_client.put_item(
      table_name: dynamodb_table_name,
      item: {
        'team' => player['team'],
        'game_date_player_uid' => "#{player['game_date']}##{player['player_id']}",
        'player_id' => player['player_id'],
        'player_name' => player['player_name'],
        'opponent' => player['opponent'],
        'at_home' => player['at_home'],
        'fg3a' => player['fg3a'],
        'fg3m' => player['fg3m'],
        'cumulative_fg3a' => player['cumulative_fg3a'],
        'cumulative_fg3m' => player['cumulative_fg3m']
      }
    )

    1
  rescue
    0
  end

  def dynamodb_table_name
    'player-game-stats'.freeze
  end

  def dynamodb_client
    @dynamodb_client ||= Aws::DynamoDB::Client.new
  end
end
