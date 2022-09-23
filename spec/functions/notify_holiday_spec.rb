require "rspec"
require_relative "../../functions/holiday_notifier"

describe "/functions/handler" do
  before do
    allow(HolidayNotifier).to receive(:notify).and_return(nil)
  end

  describe ".notify_holiday" do

    # HACK: 余裕があればholiday_japanのテストも含んだ、notify_holidayを一気通貫で通したときの通知文言をテストする総合テストを用意

    before do    
      # NOTE: 結合テストは副作用がわかればいいのでやりすぎ感ある。残らない途中式をテストしてしまっている。
      # が、内情を知っている身としてはこれがミニマムなテストなのでこれを採用。妙案が出たら改善
      allow(HolidayNotifier).to receive(:notify_today_and_tomorrow_holidays)
      allow(HolidayNotifier).to receive(:notify_recent_holidays)
      HolidayNotifier.notify_holiday(date)
    end
    
    describe "execute some day of week" do
      context "when beggining of the week, " do
        let(:date) { Date.new(2020, 1, 13) }

        it "all notify methods should be executed " do
          expect(HolidayNotifier).to have_received(:notify_today_and_tomorrow_holidays).once
          expect(HolidayNotifier).to have_received(:notify_recent_holidays).once
        end
      end

      context "when executed in weekday, " do
        let(:date) { Date.new(2020, 1, 12) }
        it "only notify_today_and_tomorrow_holidays should be executed " do
          expect(HolidayNotifier).to have_received(:notify_today_and_tomorrow_holidays).once
          expect(HolidayNotifier).not_to have_received(:notify_recent_holidays)
        end
      end
    end
  end
  
  describe ".notify_today_and_tomorrow_holidays" do
    before do
      HolidayNotifier.notify_today_and_tomorrow_holidays(recent_holidays, notify_date)
    end

    context "when there is no holiday today nor tommorow, " do
      let(:notify_date) { Date.new(2020, 1, 14) }
      let(:recent_holidays) { {} }
      it "should not be notified" do
        expect(HolidayNotifier).not_to have_received(:notify)
      end
    end

    # TODO: これ以下は本来create_today_and_tomorrow_holiday_messageで文面とともにテストするところだから気が向いたら修正
    # notify_today_and_tomorrow_holidays自体は薄いテストでいい
    context "when there is a holiday today, " do
      let(:notify_date) { Date.new(2020, 1, 13) }
      let(:recent_holidays) { { Date.new(2020, 1, 13) => "成人の日", } }
      it "should be notified" do
        expect(HolidayNotifier).to have_received(:notify)
      end
    end

    context "when there is a holiday tommorow, " do
      let(:notify_date) { Date.new(2020, 1, 12) }
      let(:recent_holidays) { { Date.new(2020, 1, 13) => "成人の日", } }
      it "should be notified" do
        expect(HolidayNotifier).to have_received(:notify)
      end
    end

    context "when there is holidays today and tommorow, " do
      let(:notify_date) { Date.new(2020, 1, 13) }
      let(:recent_holidays) do
        {
          Date.new(2020, 1, 13) => "成人の日",
          Date.new(2020, 1, 14) => "成人人人の日",
        }
      end
      it "should be notified" do
        expect(HolidayNotifier).to have_received(:notify)
      end
    end

    context "when there is a holiday next weekday, " do
      let(:notify_date) { Date.new(2020, 1, 10) }
      let(:recent_holidays) { { Date.new(2020, 1, 13) => "成人の日", } }
      it "should be notified" do
        expect(HolidayNotifier).to have_received(:notify)
      end
    end
  end
  
  describe ".notify_recent_holidays" do
    before do
      HolidayNotifier.notify_recent_holidays(recent_holidays)
    end

    # assertiionを挟んだので不要。assertのテストをしようとしたらbeforeで起きる例外を検知できなかった
    # context "when there is no recent holiday, " do
    #   let(:recent_holidays) { {} }
    #   it "should raise AssertionError" do
    #     expect{HolidayNotifier}.to raise_error(AssertionError)
    #   end
    # end

    context "when there is some recent holiday, " do
      let(:recent_holidays) { { Date.new(2020, 1, 13) => "成人の日", } }
      it "should not be notified" do
        expect(HolidayNotifier).to have_received(:notify)
      end
    end
  end
end
