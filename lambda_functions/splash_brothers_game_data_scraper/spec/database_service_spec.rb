require_relative '../source/database_service'

RSpec.describe DatabaseService do
  let(:boxscore_data) { [] }
  let(:dynamodb_client) { double }

  before do
    allow(Aws::DynamoDB::Client).to receive(:new).and_return(dynamodb_client)
  end

  describe '#create_records' do
    context 'when data is empty' do
      it 'does not create any records' do
        res = subject.create_records(boxscore_data)
        expect(res).to eq("Upserted 0 record(s)")
      end
    end

    context 'when player data does not exist in database' do
      let(:boxscore_data) do
        [
          {
            'team' => 'GS',
            'player_id' => '123',
            'player_name' => 'Steph Curry',
            'game_date' => '2022-10-18',
            'opponent' => 'LAL',
            'at_home' => true,
            'fg3m' => 4,
            'fg3a' => 13,
          },
          {
            'team' => 'LAL',
            'player_id' => '456',
            'player_name' => 'Lebron James',
            'game_date' => '2022-10-18',
            'opponent' => 'GS',
            'at_home' => false,
            'fg3m' => 3,
            'fg3a' => 10,
          },
        ]
      end

      it 'creates records' do
        query_results = double(items: [])

        expect(dynamodb_client).to receive(:put_item).with(
          table_name: 'player-game-stats',
          item: {
            'team' => 'GS',
            'game_date_player_uid' => '2022-10-18#123',
            'player_id' => '123',
            'player_name' => 'Steph Curry',
            'opponent' => 'LAL',
            'at_home' => true,
            'fg3a' => 13,
            'fg3m' => 4,
            'cumulative_fg3a' => nil,
            'cumulative_fg3m' => nil,
            'is_modified' => true
          }
        ).once.and_return(1)

        expect(dynamodb_client).to receive(:put_item).with(
          table_name: 'player-game-stats',
          item: {
            'team' => 'LAL',
            'game_date_player_uid' => '2022-10-18#456',
            'player_id' => '456',
            'player_name' => 'Lebron James',
            'opponent' => 'GS',
            'at_home' => false,
            'fg3a' => 10,
            'fg3m' => 3,
            'cumulative_fg3a' => nil,
            'cumulative_fg3m' => nil,
            'is_modified' => true
          }
        ).once.and_return(1)

        res = subject.create_records(boxscore_data)
        expect(res).to eq("Upserted 2 record(s)")
      end
    end
  end
end
