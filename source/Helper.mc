import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Application;

class Helper {

    public const nbMedicationType = 7;

    (:glance)
    public const nbMedications = 4;

    public function getMedicationIconeSymbol(medicationId as Number) as Symbol {
        switch (Properties.getValue("medication"+medicationId+"_type")) {
            case 0: 
                return $.Rez.Drawables.Spray;
            case 1:
                return $.Rez.Drawables.Tablet;
            case 2:
                return $.Rez.Drawables.Spray2;
            case 3:
                return $.Rez.Drawables.Cream;
            case 4:
                return $.Rez.Drawables.Injection;
            case 5:
                return $.Rez.Drawables.Powder;
            case 6:
                return $.Rez.Drawables.Syrup;
        }
        throw new Toybox.Lang.Exception();
    }

    public function medicationTypeMap(i as Number) as String {
        switch (i) {
            case 0: return WatchUi.loadResource(Rez.Strings.spray);
            case 1: return WatchUi.loadResource(Rez.Strings.tablet);
            case 2: return WatchUi.loadResource(Rez.Strings.spray2);
            case 3: return WatchUi.loadResource(Rez.Strings.cream);
            case 4: return WatchUi.loadResource(Rez.Strings.injection);
            case 5: return WatchUi.loadResource(Rez.Strings.powder);
            case 6: return WatchUi.loadResource(Rez.Strings.syrup);
        }
        throw new Toybox.Lang.Exception();
    }

    public function retentionUnitMap(i as Number) as String {
        switch (i) {
            case 0: return WatchUi.loadResource(Rez.Strings.week);
            case 1: return WatchUi.loadResource(Rez.Strings.month);
            case 2: return WatchUi.loadResource(Rez.Strings.year);
        }
        throw new Toybox.Lang.Exception();
    }

    public function formatTimestamp(timestamp as Time.Moment) as String {
        var date = Gregorian.info(timestamp, Time.FORMAT_SHORT);
        var dateString = Lang.format(
            "$1$:$2$:$3$ $4$/$5$/$6$",
            [
                date.hour.format("%02d"),
                date.min.format("%02d"),
                date.sec.format("%02d"),
                date.day.format("%02d"),
                date.month.format("%02d"),
                date.year
            ]
        );
        return dateString;
    }

    public function populateHistoryMenu(historyMenu as Menu2, medicationId as Number) as Void {
        var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
        if (historyData == null or historyData[medicationId] == null) {
            historyMenu.addItem(new MenuItem(Application.loadResource($.Rez.Strings.no_data_yet), null, -1, {}));

        } else {
            var historyDataForMedication = historyData[medicationId];
            for(var i = historyDataForMedication.size()-1; i >= 0; i--){
                var timestamp = new Time.Moment(historyDataForMedication[i] as Number);
                var dateString = Helper.formatTimestamp(timestamp);

                var previousTimestamp;
                if (i == historyDataForMedication.size()-1) {
                    previousTimestamp = new Moment(Time.now().value());
                } else {
                    previousTimestamp = new Time.Moment(historyDataForMedication[i+1] as Number);
                }

                var deltaInSeconds = timestamp.subtract(previousTimestamp).value();
                var deltaInHours = deltaInSeconds/3600;

                historyMenu.addItem(new MenuItem(dateString, deltaInHours.toString()+"h", i, {}));
            }
        }
    }

    public function isLeapYear(year as Number) as Number {
        return (year % 4 != 0) || ((year % 100 == 0) && (year % 400 != 0)) ? 0 : 1;
    }

    public function daysInAMonth(month as Number, year as Number) as Number {
        return (month == 2) ? (28 + Helper.isLeapYear(year)) : 31 - (month - 1) % 7 % 2;
    }
}