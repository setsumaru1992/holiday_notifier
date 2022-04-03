require "json"
require "date"
require_relative "./functions/holiday_notifier"

def lambda_handler(event:, context:)
  HolidayNotifier.notify_holiday
  { statusCode: 200, body: JSON.generate("success") }
end

if __FILE__ == $0
  lambda_handler(event: nil, context: nil)
end

