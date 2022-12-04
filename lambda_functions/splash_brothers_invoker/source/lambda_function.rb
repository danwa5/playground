require 'aws-sdk-sns'

def lambda_handler(event:, context:)
  LambdaFunction.new.call(event: nil, context: nil)
end

class LambdaFunction
  def call(event:, context:)
    results = {}

    players.each do |player|
      result = sns_client.publish(
        topic_arn: ENV['AWS_SNS_TOPIC_ARN'],
        message:   message(player)
      )

      results[player] = result.message_id
    end

    puts results

    results
  end

  private

  def players
    %w(
      steph-curry
      klay-thompson
      jordan-poole
    )
  end

  def message(player)
    { "player_name": player }.to_json
  end

  def sns_client
    @sns_client ||= Aws::SNS::Client.new
  end
end
