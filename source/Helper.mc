import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Application;

class Helper {

    public const nbMedicationType = 2;

    public function medicationIconMap(i as Number) as Bitmap {
        switch (i) {
            case 0: return new WatchUi.Bitmap({:rezId=>$.Rez.Drawables.Spray, :locY=>20});
            case 1: return new WatchUi.Bitmap({:rezId=>$.Rez.Drawables.Tablet, :locY=>20});
        }
        throw new Toybox.Lang.Exception();
    }

    public function medicationTypeMap(i as Number) as String {
        switch (i) {
            case 0: return WatchUi.loadResource(Rez.Strings.spray);
            case 1: return WatchUi.loadResource(Rez.Strings.tablet);
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

}