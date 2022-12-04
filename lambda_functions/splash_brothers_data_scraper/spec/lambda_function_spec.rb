require_relative '../source/lambda_function'
require_relative '../source/event'

RSpec.describe LambdaFunction do
  let(:player_name) { 'steph-curry' }
  let(:db_service) { double }

  describe '#call' do
    context 'when event is missing' do
      it 'raises an error' do
        expect {
          lambda_handler(event: nil, context: nil)
        }.to raise_error(ClientError, "[BadRequest] The 'player_name' key in the event payload is required")
      end
    end

    context 'when event is from API Gateway' do
      let(:event) { { 'player_name' => player_name } }

      context 'and event is missing "player_name" key' do
        let(:event) do
          { 'foo' => 'bar' }
        end

        it 'raises an error' do
          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ClientError, "[BadRequest] The 'player_name' key in the event payload is required")
        end
      end

      context 'and player game log URL cannot be found' do
        let(:event) do
          { 'player_name' => 'michael-jordan' }
        end

        it 'raises an error' do
          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ClientError, "[BadRequest] 'michael-jordan' is an invalid player name")
        end
      end

      context 'and player stats cannot be found' do
        let(:page_source) { '<html><body></body></html>' }

        it 'raises an error' do
          expect(HTTParty).to receive(:get).once.and_return(page_source)

          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ParsingError, "[InternalServerError] Problem finding player data")
        end
      end

      context 'and player stats are found' do
        let(:page_source) { File.read('spec/fixtures/player_page_with_stats.html') }

        it 'calls database service' do
          expect(HTTParty).to receive(:get).once.and_return(page_source)
          expect(DatabaseService).to receive(:new).with(player_name).once.and_return(db_service)

          expect(db_service).to receive(:create_records).with(
            [
              {
                'date' => '2022-10-18',
                'opponent' => 'vs LAL',
                '3fga' => '13',
                '3fgm' => '4'
              },
              {
                'date' => '2022-10-23',
                'opponent' => 'vs SAC',
                '3fga' => '12',
                '3fgm' => '7'
              },
              {
                'date' => '2022-11-03',
                'opponent' => '@ORL',
                '3fga' => '15',
                '3fgm' => '8'
              }
            ]
          ).once

          expect {
            lambda_handler(event: event, context: nil)
          }.to_not raise_error
        end
      end
    end

    context 'when event is from SNS' do
      let(:event) do
        {
          'Records' => [
            {
              'Sns' => {
                'TopicArn' => 'arn:aws:sns:us-west-1:ACCT_ID:TOPIC',
                'Message'  => message
              }
            }
          ]
        }
      end

      context 'and event is missing "player_name" key' do
        let(:message) { {}.to_json }

        it 'raises an error' do
          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ClientError, "[BadRequest] The 'player_name' key in the event payload is required")
        end
      end

      context 'and player game log URL cannot be found' do
        let(:message) do
          { 'player_name' => 'michael-jordan' }.to_json
        end

        it 'raises an error' do
          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ClientError, "[BadRequest] 'michael-jordan' is an invalid player name")
        end
      end

      context 'and player stats cannot be found' do
        let(:message) do
          { 'player_name' => player_name }.to_json
        end
        let(:page_source) { '<html><body></body></html>' }

        it 'raises an error' do
          expect(HTTParty).to receive(:get).once.and_return(page_source)

          expect {
            lambda_handler(event: event, context: nil)
          }.to raise_error(ParsingError, "[InternalServerError] Problem finding player data")
        end
      end

      context 'and player stats are found' do
        let(:message) do
          { 'player_name' => player_name }.to_json
        end
        let(:page_source) { File.read('spec/fixtures/player_page_with_stats.html') }

        it 'calls database service' do
          expect(HTTParty).to receive(:get).once.and_return(page_source)
          expect(DatabaseService).to receive(:new).with(player_name).once.and_return(db_service)

          expect(db_service).to receive(:create_records).with(
            [
              {
                'date' => '2022-10-18',
                'opponent' => 'vs LAL',
                '3fga' => '13',
                '3fgm' => '4'
              },
              {
                'date' => '2022-10-23',
                'opponent' => 'vs SAC',
                '3fga' => '12',
                '3fgm' => '7'
              },
              {
                'date' => '2022-11-03',
                'opponent' => '@ORL',
                '3fga' => '15',
                '3fgm' => '8'
              }
            ]
          ).once

          expect {
            lambda_handler(event: event, context: nil)
          }.to_not raise_error
        end
      end
    end
  end
end
