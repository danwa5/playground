require 'digest'

def lambda_handler(event:, context:)
  LambdaFunction.handler(event: event, context: context)
end

class LambdaFunction
  attr_reader :event

  def self.handler(event:, context:)
    @event = event

    digest = ::Digest::SHA2.hexdigest(ENV['SHARED_SECRET_KEY'].to_s)
    authorization = event['headers']['authorization'].to_s
    permission = authorization == digest ? 'Allow' : 'Deny'

    {
      'principalId': 'user',
      'policyDocument': {
        'Version': '2012-10-17',
        'Statement': [
          {
            "Action": "execute-api:Invoke",
            "Effect": permission,
            "Resource": event['methodArn']
          }
        ]
      }
    }
  end
end
