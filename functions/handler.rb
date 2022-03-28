require "json"
require "date"
require "holiday_japan"
require 'standard_assert'

include ::Assert

def lambda_handler(event:, context:)
  HolidayNotifier.new.notify_holiday # (Date.new(2019, 12, 31))
  { statusCode: 200, body: JSON.generate("success") }
end

class HolidayNotifier # テストでスパイさせるために無理やりクラス化。他の方法が見つかれば解除
  class << self
    def notify_holiday(notify_date = Date.today)
      recent_holidays = fetch_recent_holidays(notify_date)

      notify_today_and_tomorrow_holidays(recent_holidays, notify_date)
      notify_recent_holidays(recent_holidays) if notify_date.monday?
    end
    
    def fetch_recent_holidays(notify_date, recent_days: 14)
      p HolidayJapan.between("2020-1-1","2020-1-31")
      {
          Date.new(2020, 1, 1) => "元日",
          Date.new(2020, 1, 13) => "成人の日",
      }
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
         ja_message << "今日は日本の祝日です（#{todays_holiday}）。\n"
         en_message << "Today is a Japanese holiday.\n"
      end
      
      if !tomorrows_holiday.nil?
         ja_message << "明日は日本の祝日です（#{tomorrows_holiday}）。\n"
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
      p message
    end
  end
end

# 祝日メモ
# {#<Date: 2020-01-01 ((2458850j,0s,0n),+0s,2299161j)>=>"元日",
#     #<Date: 2020-01-13 ((2458862j,0s,0n),+0s,2299161j)>=>"成人の日",
#     #<Date: 2020-02-11 ((2458891j,0s,0n),+0s,2299161j)>=>"建国記念の日",
#     #<Date: 2020-02-23 ((2458903j,0s,0n),+0s,2299161j)>=>"天皇誕生日",
#     #<Date: 2020-02-24 ((2458904j,0s,0n),+0s,2299161j)>=>"振替休日",
#     #<Date: 2020-03-20 ((2458929j,0s,0n),+0s,2299161j)>=>"春分の日",
#     #<Date: 2020-04-29 ((2458969j,0s,0n),+0s,2299161j)>=>"昭和の日",
#     #<Date: 2020-05-03 ((2458973j,0s,0n),+0s,2299161j)>=>"憲法記念日",
#     #<Date: 2020-05-04 ((2458974j,0s,0n),+0s,2299161j)>=>"みどりの日",
#     #<Date: 2020-05-05 ((2458975j,0s,0n),+0s,2299161j)>=>"こどもの日",
#     #<Date: 2020-05-06 ((2458976j,0s,0n),+0s,2299161j)>=>"振替休日",
#     #<Date: 2020-07-23 ((2459054j,0s,0n),+0s,2299161j)>=>"海の日",
#     #<Date: 2020-07-24 ((2459055j,0s,0n),+0s,2299161j)>=>"スポーツの日",
#     #<Date: 2020-08-10 ((2459072j,0s,0n),+0s,2299161j)>=>"山の日",
#     #<Date: 2020-09-21 ((2459114j,0s,0n),+0s,2299161j)>=>"敬老の日",
#     #<Date: 2020-09-22 ((2459115j,0s,0n),+0s,2299161j)>=>"秋分の日",
#     #<Date: 2020-11-03 ((2459157j,0s,0n),+0s,2299161j)>=>"文化の日",
#     #<Date: 2020-11-23 ((2459177j,0s,0n),+0s,2299161j)>=>"勤労感謝の日"}

if __FILE__ == $0
  HolidayNotifier.notify_holiday(Date.new(2019, 12, 31))
end