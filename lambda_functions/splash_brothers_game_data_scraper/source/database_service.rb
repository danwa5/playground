require 'aws-sdk-dynamodb'

class DatabaseService
  def create_records(boxscore_data)
    return output_msg if boxscore_data.empty?

    records_created = 0

    boxscore_data.each do |player|
      last_game = find_player_last_game(player)

      # skip if player's game log already exists in db
      next if last_game && last_game['game_date'] == player['game_date']

      # update player's season games played and 3pt totals
      player = update_season_totals(player, last_game)

      puts "Upserting record for #{player['player_name']}"
      records_created += create_record(player)
    end

    output_msg(records_created)
  end

  private

  def output_msg(record_count = 0)
    "Upserted #{record_count} record(s)"
  end

  def update_season_totals(player, last_game)
    # get season totals from last game
    games_played = current_season_games_played(last_game)
    cumulative_fg3m, cumulative_fg3a = current_season_3pt_totals(last_game)

    games_played += (player['fg3a'].nil? ? 0 : 1)
    cumulative_fg3m += (player['fg3m'] || 0).to_i
    cumulative_fg3a += (player['fg3a'] || 0).to_i

    player.merge(
      'games_played' => games_played,
      'cumulative_fg3a' => cumulative_fg3a,
      'cumulative_fg3m' => cumulative_fg3m
    )
  end

  def current_season_games_played(game)
    return 0 if game.nil?

    (game['games_played'] || 0).to_i
  end

  def current_season_3pt_totals(game)
    return [0, 0] if game.nil?

    [(game['cumulative_fg3m'] || 0).to_i, (game['cumulative_fg3a'] || 0).to_i]
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
      projection_expression: 'game_date_player_uid, game_date, player_id, player_name, games_played, cumulative_fg3a, cumulative_fg3m'
    )

    resp.items.empty? ? nil : resp.items.first
  end

  def create_record(player)
    resp = dynamodb_client.put_item(
      table_name: dynamodb_table_name,
      item: {
        'team' => player['team'],
        'game_date_player_uid' => "#{player['game_date']}##{player['player_id']}",
        'game_date_cumulative_fg3a' => "#{player['game_date']}##{zero_pad_num(player['cumulative_fg3a'])}",
        'game_date_cumulative_fg3m' => "#{player['game_date']}##{zero_pad_num(player['cumulative_fg3m'])}",
        'game_date' => player['game_date'],
        'player_id' => player['player_id'],
        'player_name' => player['player_name'],
        'opponent' => player['opponent'],
        'at_home' => player['at_home'],
        'fg3a' => player['fg3a'],
        'fg3m' => player['fg3m'],
        'games_played' => player['games_played'],
        'cumulative_fg3a' => player['cumulative_fg3a'],
        'cumulative_fg3m' => player['cumulative_fg3m']
      }
    )

    1
  rescue
    0
  end

  def zero_pad_num(num)
    "%04d" % num
  end

  def dynamodb_table_name
    'player-game-stats'.freeze
  end

  def dynamodb_client
    @dynamodb_client ||= Aws::DynamoDB::Client.new
  end
end
