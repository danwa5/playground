# This class handles an event from either API Gateway or SNS
#
# An event from API Gateway looks like this:
#   {
#     "game_date" => "2022-10-18"
#   }
#
# An event from SNS looks like this:
#   {
#     "Records" => [
#       {
#       "EventSource" => "aws:sns",
#       "EventVersion" => "1.0",
#       "EventSubscriptionArn" => "arn:aws:sns:us-west-1:ACCT_ID:TOPIC:1dd99586-4662-469d-b93e-4776ebc34e89",
#         "Sns" => {
#           "Type"      => "Notification",
#           "TopicArn"  => "arn:aws:sns:us-west-1:ACCT_ID:TOPIC",
#           "Message"   => "{\"game_date\":\"2022-10-18\"}"
#           "Timestamp" => "2022-12-03T15:55:00.412Z",
#         }
#       }
#     ]
#   }
# Note: SNS will only send one record per notification,
# see https://aws.amazon.com/sns/faqs (Reliability section).

class Event
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def game_date
    source.fetch('game_date')
  end

  private

  def source
    if event.has_key?('Records')
      h = event['Records'].first['Sns']
      JSON.parse(h['Message'])
    else
      event
    end
  end
end
