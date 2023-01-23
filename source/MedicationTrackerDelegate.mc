import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Time;

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("take") or id.equals("history")) {
            var menuTitle;
            if (id.equals("take")) {
                menuTitle = "Take medication";
            } else {
                menuTitle = "History";
            }

            var menu = new WatchUi.Menu2({:title=>menuTitle});

            var medicationIconMap = {0=>new WatchUi.Bitmap({:rezId=>Rez.Drawables.Spray, :locY=>20}),
                                     1=>new WatchUi.Bitmap({:rezId=>Rez.Drawables.Tablet, :locY=>20})};

            menu.addItem(new IconMenuItem(Properties.getValue("medication1_name"), null, 1, medicationIconMap[Properties.getValue("medication1_type")], {}));

            for (var i = 2; i <= 5; i++) {
                if (Properties.getValue("medication"+i+"_en")){
                    menu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), null, i, medicationIconMap[Properties.getValue("medication"+i+"_type")], {}));
                }
            }
            
            if (id.equals("take")) {
                WatchUi.pushView(menu, new TakeMenuDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.pushView(menu, new HistoryMenuDelegate(), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("settings")) {
            var retentionUnitMap = {0=>"Week", 1=>"Month", 2=>"Year"};
            var retention = Properties.getValue("retention_length") + " " + retentionUnitMap[Properties.getValue("retention_unit")];

            var settingsMenu = new WatchUi.Menu2({:title=>"Settings"});
            settingsMenu.addItem(new MenuItem("Keep data for", retention, "retention", {}));
            settingsMenu.addItem(new MenuItem("Edit settings via Garmin Connect App", null, "info", {}));
            
            WatchUi.pushView(settingsMenu, new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);

        } else {
            WatchUi.requestUpdate();
        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        System.exit();
    }
}

class TakeMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        var message = "Take "+Properties.getValue("medication"+id+"_name")+"?";
        var dialog = new WatchUi.Confirmation(message);
        WatchUi.pushView(dialog, new TakeConfirmationDelegate(id), WatchUi.SLIDE_IMMEDIATE);
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}


class TakeConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    
    var id;

    //! Constructor
    public function initialize(medication_id) {
        self.id = medication_id;
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
            var timestamp = Time.now().value();

            if (historyData == null) {
                historyData = {id=>[timestamp]};
            } else if (historyData[id] == null) {
                historyData[id] = [timestamp];
            } else {
                historyData[id].add(timestamp);
            }

            // Flush old data out of the database
            var retentionUnitMap = {0=>7*Gregorian.SECONDS_PER_DAY,
                                    1=>31*Gregorian.SECONDS_PER_DAY,
                                    2=>Gregorian.SECONDS_PER_YEAR};
            var retention = Properties.getValue("retention_length") * retentionUnitMap[Properties.getValue("retention_unit")];
            var retentionLimit = Time.now().subtract(new Time.Duration(retention)).value();
            for (var i = 1; i <= 5; i++) {
                if (historyData[i] != null) {
                    for (var j = historyData[i].size()-1; j >= 0; j--) {
                        if (historyData[i][j] < retentionLimit) {
                            historyData[i] = historyData[i].slice(j+1, historyData[i].size());
                        }
                    }
                }
            }

            Storage.setValue("history_data", historyData);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}

class HistoryMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as Integer;
        var historyMenu = new WatchUi.Menu2({:title=>Properties.getValue("medication"+id+"_name")});

        var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
        if (historyData == null or historyData[id] == null) {
            historyMenu.addItem(new MenuItem("No data yet", null, 0, {}));
            WatchUi.pushView(historyMenu, new MedicationTrackerDelegate(), WatchUi.SLIDE_LEFT);

        } else {
            var historyDataForMedication = historyData[id];
            for(var i = historyDataForMedication.size()-1; i >= 0; i--){
                var timestamp = new Time.Moment(historyDataForMedication[i] as Number);

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
            // TODO : Add a custom handler here to allow deleting or editing data points
            WatchUi.pushView(historyMenu, new DatapointTrackerDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class MedicationTrackerDelegate extends WatchUi.BehaviorDelegate {

    //! Constructor
    public function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Handle the back key being pressed
    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

class DatapointTrackerDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
