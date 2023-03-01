require 'aws-sdk-dynamodb'

class DatabaseService
  def create_records(boxscore_data)
    return output_msg if boxscore_data.empty?

    records_created = 0

    boxscore_data.each do |player|
      puts "Upserting record for #{player['player_name']}"
      records_created += create_record(player)
    end

    output_msg(records_created)
  end

  private

  def output_msg(record_count = 0)
    "Upserted #{record_count} record(s)"
  end

  def create_record(player)
    attrs = {
      'team' => player['team'],
      'game_date_player_uid' => "#{player['game_date']}##{player['player_id']}",
      'player_id' => player['player_id'],
      'player_name' => player['player_name'],
      'opponent' => player['opponent'],
      'at_home' => player['at_home'],
      'fg3a' => player['fg3a'],
      'fg3m' => player['fg3m']
    }

    attrs.merge!(default_attrs)

    resp = dynamodb_client.put_item(
      table_name: dynamodb_table_name,
      item: attrs
    )

    1
  rescue
    0
  end

  def default_attrs
    @default_attrs ||= begin
      {
        'is_modified' => true,
        'cumulative_fg3a' => nil,
        'cumulative_fg3m' => nil
      }
    end
  end

  def dynamodb_table_name
    'player-game-stats'.freeze
  end

  def dynamodb_client
    @dynamodb_client ||= Aws::DynamoDB::Client.new
  end
end
