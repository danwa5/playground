require_relative '../source/lambda_function'
require 'byebug'

RSpec.describe LambdaFunction do
  let(:method_arn) { 'arn:aws:execute-api:REGION:ACCOUNT-ID:API-ID/*/POST/scrape' }
  let(:event) do
    {
      'methodArn' => method_arn,
      'headers' => {
        'Authorization' => auth_token
      }
    }
  end

  describe '.handler' do
    before do
      allow(::Digest::SHA2).to receive(:hexdigest).and_return('valid-token')
    end

    context 'when event has an invalid authentication token' do
      let(:auth_token) { 'invalid-token' }

      it 'returns a Deny IAM policy' do
        res = described_class.handler(event: event, context: nil)

        expect(res).to eq({
          'principalId': 'user',
          'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
              {
                "Action": "execute-api:Invoke",
                "Effect": "Deny",
                "Resource": method_arn
              }
            ]
          }
        })
      end
    end

    context 'when event has a valid authentication token' do
      let(:auth_token) { 'valid-token' }

      it 'returns an Allow IAM policy' do
        res = described_class.handler(event: event, context: nil)

        expect(res).to eq({
          'principalId': 'user',
          'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
              {
                "Action": "execute-api:Invoke",
                "Effect": "Allow",
                "Resource": method_arn
              }
            ]
          }
        })
      end
    end
  end
end
