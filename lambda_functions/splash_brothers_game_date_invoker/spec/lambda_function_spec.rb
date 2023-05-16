require_relative '../source/lambda_function'
require 'byebug'

RSpec.describe LambdaFunction do
  let(:sns_client) { double }

  describe '#call' do
    context 'when event is missing' do
      it 'raises an error' do
        expect {
          lambda_handler(event: nil, context: nil)
        }.to raise_error(ClientError, "[BadRequest] The 'game_date' key in the event payload is required")
      end
    end

    context 'when event is invalid' do
      let(:event) { { 'game_date' => 'abc' } }

      it 'raises an error' do
        expect {
          lambda_handler(event: event, context: nil)
        }.to raise_error(ParsingError, "[BadRequest] The 'game_date' key in the event payload is invalid")
      end
    end

    context 'when there are no game results' do
      let(:event) { { 'game_date' => '2022-10-17' } }
      let(:page_source) { '<html><body></body></html>' }

      it 'returns an empty hash' do
        expect(HTTParty).to receive(:get)
          .with('https://www.cbssports.com/nba/schedule/20221017/')
          .once.and_return(page_source)

        res = lambda_handler(event: event, context: nil)

        expect(res).to eq({})
      end
    end

    context 'when game results are found' do
      let(:event) { { 'game_date' => '2022-10-18' } }
      let(:page_source) { File.read('spec/fixtures/schedule.html') }

      before do
        allow(Aws::SNS::Client).to receive(:new).and_return(sns_client)
      end

      it 'publishes a SNS message for each boxscore url' do
        expect(HTTParty).to receive(:get)
          .with('https://www.cbssports.com/nba/schedule/20221018/')
          .once.and_return(page_source)

        expect(sns_client).to receive(:publish).with(
          topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
          message:   { 'boxscore_url': 'https://www.cbssports.com/nba/gametracker/recap/NBA_20221018_PHI@BOS/' }.to_json
        ).and_return(double(message_id: '123'))

        expect(sns_client).to receive(:publish).with(
          topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
          message:   { 'boxscore_url': 'https://www.cbssports.com/nba/gametracker/recap/NBA_20221018_LAL@GS/' }.to_json
        ).and_return(double(message_id: '456'))

        res = lambda_handler(event: event, context: nil)

        expect(res).to eq(
          'https://www.cbssports.com/nba/gametracker/recap/NBA_20221018_PHI@BOS/' => '123',
          'https://www.cbssports.com/nba/gametracker/recap/NBA_20221018_LAL@GS/' => '456'
        )
      end
    end
  end
end
