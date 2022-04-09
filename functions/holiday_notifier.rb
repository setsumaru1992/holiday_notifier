require "date"
require "holiday_japan"
require "standard_assert"
require "slack-notifier"

include ::Assert

# ローカルでのスクリプト実行時は環境変数セット export WEBHOOK_URL=https://xxx.xx
SLACK = Slack::Notifier.new(ENV["WEBHOOK_URL"])

class HolidayNotifier # テストでスパイさせるために無理やりクラス化。他の方法が見つかれば解除
  class << self
    def notify_holiday(notify_date = Date.today)
      recent_holidays = fetch_recent_holidays(notify_date)

      notify_today_and_tomorrow_holidays(recent_holidays, notify_date)
      notify_recent_holidays(recent_holidays) if notify_date.monday?
    end
    
    def fetch_recent_holidays(notify_date, recent_days: 14)
      HolidayJapan.between(notify_date.to_s, (notify_date + (recent_days - 1)).to_s)
    end
    
    # private
    
    def notify_today_and_tomorrow_holidays(recent_holidays, notify_date)
      todays_holiday = recent_holidays.select { |holiday_date, _| holiday_date == notify_date }.values.first
      tomorrows_holiday = recent_holidays.select { |holiday_date, _| holiday_date == notify_date.next_day }.values.first
      
      require_notify = !todays_holiday.nil? || !tomorrows_holiday.nil?
      return unless require_notify

      message = create_today_and_tomorrow_holiday_message(todays_holiday, tomorrows_holiday)
      notify(message)
    end

    def create_today_and_tomorrow_holiday_message(todays_holiday, tomorrows_holiday)
      assert(!todays_holiday.nil? || !tomorrows_holiday.nil?)
      ja_message = ""
      en_message = ""
      
      if !todays_holiday.nil?
         ja_message << "今日は日本の祝日（#{todays_holiday}）です\n"
         en_message << "Today is a Japanese holiday.\n"
      end
      
      if !tomorrows_holiday.nil?
         ja_message << "明日は日本の祝日（#{tomorrows_holiday}）です\n"
         en_message << "Tomorrow is a Japanese holiday.\n"
      end
      
      "#{ja_message}\n#{en_message}"
    end
    
    JA_DAYS_OF_WEEK = ["日", "月", "火", "水", "木", "金", "土"]
    EN_DAYS_OF_WEEK = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    def notify_recent_holidays(recent_holidays)
      return if recent_holidays.empty?
      
      message = create_recent_holidays(recent_holidays)
      notify(message)
    end 

    def create_recent_holidays(recent_holidays)
      ja_holiday_messages = []
      en_holiday_messages = []
      recent_holidays.each do |holiday_date, holiday_name|
          ja_holiday_messages << "#{holiday_date}(#{JA_DAYS_OF_WEEK[holiday_date.wday]}) #{holiday_name}"
          en_holiday_messages << "#{holiday_date}(#{EN_DAYS_OF_WEEK[holiday_date.wday]})"
      end
      
     "今週の祝日\n#{ja_holiday_messages.join(", ")}\n\nJapanese holidays\n#{en_holiday_messages.join(", ")}"
    end
    
    def notify(message)
      SLACK.ping(message)
    end
  end
end

DATE_OF_MONDAY_WITH_TOMMOROW_HOLIDAY = Date.new(2021, 5, 3)
if __FILE__ == $0
  HolidayNotifier.notify_holiday(DATE_OF_MONDAY_WITH_TOMMOROW_HOLIDAY)
end
