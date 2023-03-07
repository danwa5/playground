require_relative '../source/database_service'

RSpec.describe DatabaseService do
  let(:boxscore_data) { [] }
  let(:dynamodb_client) { double }

  before do
    allow(Aws::DynamoDB::Client).to receive(:new).and_return(dynamodb_client)
  end

  describe '#create_records' do
    context 'when box score data is empty' do
      it 'does not create any records' do
        res = subject.create_records(boxscore_data)
        expect(res).to eq("Upserted 0 record(s)")
      end
    end

    context 'when box score data is present' do
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
            'team' => 'GS',
            'player_id' => '456',
            'player_name' => 'Klay Thompson',
            'game_date' => '2022-10-18',
            'opponent' => 'LAL',
            'at_home' => true,
            'fg3m' => 0,
            'fg3a' => 0,
          },
          {
            'team' => 'LAL',
            'player_id' => '789',
            'player_name' => 'Lebron James',
            'game_date' => '2022-10-18',
            'opponent' => 'GS',
            'at_home' => false,
            'fg3m' => nil,
            'fg3a' => nil,
          },
        ]
      end

      context 'and players do not have existing data in database' do
        it 'creates records' do
          allow(dynamodb_client).to receive(:query).and_return(double(items: []))

          expect(dynamodb_client).to receive(:put_item).with(
            table_name: 'player-game-stats',
            item: {
              'team' => 'GS',
              'game_date_player_uid' => '2022-10-18#123',
              'game_date_cumulative_fg3a' => '2022-10-18#0013',
              'game_date_cumulative_fg3m' => '2022-10-18#0004',
              'game_date' => '2022-10-18',
              'player_id' => '123',
              'player_name' => 'Steph Curry',
              'opponent' => 'LAL',
              'at_home' => true,
              'fg3a' => 13,
              'fg3m' => 4,
              'cumulative_fg3a' => 13,
              'cumulative_fg3m' => 4,
            }
          ).once.and_return(1)

          expect(dynamodb_client).to receive(:put_item).with(
            table_name: 'player-game-stats',
            item: {
              'team' => 'GS',
              'game_date_player_uid' => '2022-10-18#456',
              'game_date_cumulative_fg3a' => '2022-10-18#0000',
              'game_date_cumulative_fg3m' => '2022-10-18#0000',
              'game_date' => '2022-10-18',
              'player_id' => '456',
              'player_name' => 'Klay Thompson',
              'opponent' => 'LAL',
              'at_home' => true,
              'fg3a' => 0,
              'fg3m' => 0,
              'cumulative_fg3a' => 0,
              'cumulative_fg3m' => 0,
            }
          ).once.and_return(1)

          expect(dynamodb_client).to receive(:put_item).with(
            table_name: 'player-game-stats',
            item: {
              'team' => 'LAL',
              'game_date_player_uid' => '2022-10-18#789',
              'game_date_cumulative_fg3a' => '2022-10-18#0000',
              'game_date_cumulative_fg3m' => '2022-10-18#0000',
              'game_date' => '2022-10-18',
              'player_id' => '789',
              'player_name' => 'Lebron James',
              'opponent' => 'GS',
              'at_home' => false,
              'fg3a' => nil,
              'fg3m' => nil,
              'cumulative_fg3a' => 0,
              'cumulative_fg3m' => 0,
            }
          ).once.and_return(1)

          res = subject.create_records(boxscore_data)
          expect(res).to eq("Upserted 3 record(s)")
        end
      end

      context 'and players have existing data in database' do
        let(:query_results_1) { double(items: [{ 'cumulative_fg3a' => 10, 'cumulative_fg3m' => 5}]) }
        let(:query_results_2) { double(items: [{ 'cumulative_fg3a' => 2, 'cumulative_fg3m' => 1}]) }
        let(:query_results_3) { double(items: [{ 'cumulative_fg3a' => 0, 'cumulative_fg3m' => 0}]) }

        it 'creates records' do
          allow(dynamodb_client).to receive(:query).and_return(query_results_1, query_results_2, query_results_3)

          expect(dynamodb_client).to receive(:put_item).with(
            table_name: 'player-game-stats',
            item: {
              'team' => 'GS',
              'game_date_player_uid' => '2022-10-18#123',
              'game_date_cumulative_fg3a' => '2022-10-18#0023',
              'game_date_cumulative_fg3m' => '2022-10-18#0009',
              'game_date' => '2022-10-18',
              'player_id' => '123',
              'player_name' => 'Steph Curry',
              'opponent' => 'LAL',
              'at_home' => true,
              'fg3a' => 13,
              'fg3m' => 4,
              'cumulative_fg3a' => 23,
              'cumulative_fg3m' => 9,
            }
          ).once.and_return(1)

          expect(dynamodb_client).to receive(:put_item).with(
            table_name: 'player-game-stats',
            item: {
              'team' => 'GS',
              'game_date_player_uid' => '2022-10-18#456',
              'game_date_cumulative_fg3a' => '2022-10-18#0002',
              'game_date_cumulative_fg3m' => '2022-10-18#0001',
              'game_date' => '2022-10-18',
              'player_id' => '456',
              'player_name' => 'Klay Thompson',
              'opponent' => 'LAL',
              'at_home' => true,
              'fg3a' => 0,
              'fg3m' => 0,
              'cumulative_fg3a' => 2,
              'cumulative_fg3m' => 1,
            }
          ).once.and_return(1)

          expect(dynamodb_client).to receive(:put_item).with(
            table_name: 'player-game-stats',
            item: {
              'team' => 'LAL',
              'game_date_player_uid' => '2022-10-18#789',
              'game_date_cumulative_fg3a' => '2022-10-18#0000',
              'game_date_cumulative_fg3m' => '2022-10-18#0000',
              'game_date' => '2022-10-18',
              'player_id' => '789',
              'player_name' => 'Lebron James',
              'opponent' => 'GS',
              'at_home' => false,
              'fg3a' => nil,
              'fg3m' => nil,
              'cumulative_fg3a' => 0,
              'cumulative_fg3m' => 0,
            }
          ).once.and_return(1)

          res = subject.create_records(boxscore_data)
          expect(res).to eq("Upserted 3 record(s)")
        end
      end
    end
  end
end
