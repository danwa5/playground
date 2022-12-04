require_relative '../source/lambda_function'
require 'byebug'

RSpec.describe LambdaFunction do
  let(:sns_client) { double }

  describe '#call' do
    before do
      allow(Aws::SNS::Client).to receive(:new).and_return(sns_client)
    end

    it 'publishes a SNS message for each player' do
      expect(sns_client).to receive(:publish).with(
        topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
        message:   { "player_name": "steph-curry" }.to_json
      ).and_return(double(message_id: "123"))

      expect(sns_client).to receive(:publish).with(
        topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
        message:   { "player_name": "klay-thompson" }.to_json
      ).and_return(double(message_id: "456"))

      expect(sns_client).to receive(:publish).with(
        topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
        message:   { "player_name": "jordan-poole" }.to_json
      ).and_return(double(message_id: "789"))

      res = lambda_handler(event: nil, context: nil)

      expect(res).to eq(
        'steph-curry' => '123',
        'klay-thompson' => '456',
        'jordan-poole' => '789'
      )
    end
  end
end
