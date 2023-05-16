require_relative '../source/lambda_function'

RSpec.describe LambdaFunction do
  let(:boxscore_url) { 'https://www.cbssports.com/nba/gametracker/boxscore/NBA_20221018_LAL@GS/' }
  let(:db_service) { double }

  describe '#call' do
    context 'when event is missing' do
      it 'raises an error' do
        expect {
          lambda_handler(event: nil, context: nil)
        }.to raise_error(ClientError, "[BadRequest] The 'boxscore_url' key in the event payload is required")
      end
    end

    context 'when event is from API Gateway' do
      let(:event) { { 'boxscore_url' => boxscore_url } }

      context 'and event is missing "boxscore_url" key' do
        let(:event) do
          { 'foo' => 'bar' }
        end

        it 'raises an error' do
          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ClientError, "[BadRequest] The 'boxscore_url' key in the event payload is required")
        end
      end

      context 'and box score stats cannot be found' do
        let(:page_source) { '<html><body></body></html>' }

        it 'raises an error' do
          expect(HTTParty).to receive(:get).once.and_return(page_source)

          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ParsingError, "[InternalServerError] Problem finding box score data")
        end
      end

      context 'and box score stats are found' do
        let(:page_source) { File.read('spec/fixtures/boxscore_page.html') }

        it 'scrapes player data from home and away teams' do
          expect(HTTParty).to receive(:get).once.and_return(page_source)
          expect(DatabaseService).to receive(:new).once.and_return(db_service)

          expect(db_service).to receive(:create_records).with(
            [
              {
                'team' => 'LAL',
                'player_id' => '400553',
                'player_name' => 'L. James',
                'game_date' => '2022-10-18',
                'opponent' => 'GS',
                'at_home' => false,
                'fg3m' => 3,
                'fg3a' => 10,
              },
              {
                'team' => 'LAL',
                'player_id' => '1622555',
                'player_name' => 'R. Westbrook',
                'game_date' => '2022-10-18',
                'opponent' => 'GS',
                'at_home' => false,
                'fg3m' => 1,
                'fg3a' => 3,
              },
              {
                'team' => 'LAL',
                'player_id' => '2268681',
                'player_name' => 'A. Reaves',
                'game_date' => '2022-10-18',
                'opponent' => 'GS',
                'at_home' => false,
                'fg3m' => 0,
                'fg3a' => 2,
              },
              {
                'team' => 'LAL',
                'player_id' => '2067702',
                'player_name' => 'D. Schroder',
                'game_date' => '2022-10-18',
                'opponent' => 'GS',
                'at_home' => false,
                'fg3m' => nil,
                'fg3a' => nil,
              },
              {
                'team' => 'GS',
                'player_id' => '1685204',
                'player_name' => 'S. Curry',
                'game_date' => '2022-10-18',
                'opponent' => 'LAL',
                'at_home' => true,
                'fg3m' => 4,
                'fg3a' => 13,
              },
              {
                'team' => 'GS',
                'player_id' => '1647559',
                'player_name' => 'K. Thompson',
                'game_date' => '2022-10-18',
                'opponent' => 'LAL',
                'at_home' => true,
                'fg3m' => 2,
                'fg3a' => 6,
              },
              {
                'team' => 'GS',
                'player_id' => '2892690',
                'player_name' => 'J. Poole',
                'game_date' => '2022-10-18',
                'opponent' => 'LAL',
                'at_home' => true,
                'fg3m' => 2,
                'fg3a' => 9,
              },
              {
                'team' => 'GS',
                'player_id' => '498289',
                'player_name' => 'A. Iguodala',
                'game_date' => '2022-10-18',
                'opponent' => 'LAL',
                'at_home' => true,
                'fg3m' => nil,
                'fg3a' => nil,
              }
            ]
          ).once

          lambda_handler(event: event, context: nil)
        end
      end
    end
  end
end
