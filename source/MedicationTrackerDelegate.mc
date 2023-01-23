import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Time;

var medicationIconMap = {0=>new WatchUi.Bitmap({:rezId=>Rez.Drawables.Spray, :locY=>20}),
                        1=>new WatchUi.Bitmap({:rezId=>Rez.Drawables.Tablet, :locY=>20})};
var medicationTypeMap = {0=>WatchUi.loadResource(Rez.Strings.spray), 1=>WatchUi.loadResource(Rez.Strings.tablet)};
var retentionUnitMap = {0=>WatchUi.loadResource(Rez.Strings.week), 1=>WatchUi.loadResource(Rez.Strings.month), 2=>WatchUi.loadResource(Rez.Strings.year)};

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

            for (var i = 1; i <= 5; i++) {
                if (Properties.getValue("medication"+i+"_en")){
                    menu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), null, i, medicationIconMap[Properties.getValue("medication"+i+"_type")], {}));
                }
            }
            
            if (id.equals("take")) {
                ViewManager.pushView(menu, new TakeMenuDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                ViewManager.pushView(menu, new HistoryMenuDelegate(), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("settings")) {
            var retention = Properties.getValue("retention_length") + " " + retentionUnitMap[Properties.getValue("retention_unit")];

            var settingsMenu = new WatchUi.Menu2({:title=>"Settings"});
            settingsMenu.addItem(new MenuItem("Keep data for", retention, "retention", {}));

            for (var i = 1; i <= 5; i++) {
                var enabled = Properties.getValue("medication"+i+"_en") ? "Enabled" : "Disabled";
                settingsMenu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), enabled, i, medicationIconMap[Properties.getValue("medication"+i+"_type")], {}));
            }
            
            ViewManager.pushView(settingsMenu, new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);

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
        ViewManager.pushView(dialog, new TakeConfirmationDelegate(id), WatchUi.SLIDE_IMMEDIATE);
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
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
            ViewManager.popView(WatchUi.SLIDE_RIGHT);
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
            ViewManager.pushView(historyMenu, new MedicationTrackerDelegate(), WatchUi.SLIDE_LEFT);

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
            ViewManager.pushView(historyMenu, new DatapointTrackerDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
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

        if (id.equals("retention")) {
            ViewManager.pushView(new RetentionPicker(), new RetentionPickerDelegate(), WatchUi.SLIDE_LEFT);

        } else {
            var enabled = Properties.getValue("medication"+id+"_en");

            var medicationSettingMenu = new WatchUi.Menu2({:title=>Properties.getValue("medication"+id+"_name")});
            
            medicationSettingMenu.addItem(new MenuItem("Name", Properties.getValue("medication"+id+"_name"), ["name", id], {}));
            medicationSettingMenu.addItem(new ToggleMenuItem("Status", {:enabled=>"Enabled", :disabled=>"Disabled"}, ["status", id], enabled, {}));
            medicationSettingMenu.addItem(new IconMenuItem("Type", medicationTypeMap[Properties.getValue("medication"+id+"_type")], ["type", id], medicationIconMap[Properties.getValue("medication"+id+"_type")], {}));
            
            ViewManager.pushView(medicationSettingMenu, new MedicationSettingMenuMenuDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
    }
}

class MedicationSettingMenuMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var action = item.getId()[0] as String;
        var id = item.getId()[1] as Number;

        if (action.equals("name")) {
            var initialText = Properties.getValue("medication"+id+"_name");
            var textPicker = new StringPicker(initialText);
            ViewManager.pushView(
                textPicker,
                new MedicationNamePickerDelegate(textPicker, id),
                WatchUi.SLIDE_LEFT
            );

        } else if (action.equals("status")) {
            var currentStatus = Properties.getValue("medication"+id+"_en") as Boolean;
            Properties.setValue("medication"+id+"_en", !currentStatus);
            var parent_menu = viewStack[viewStack.size()-2] as Menu2;
            parent_menu.getItem(id).setSubLabel(!currentStatus ? "Enabled" : "Disabled");

        } else if (action.equals("type")) {
            var currentType = Properties.getValue("medication"+id+"_type") as Number;
            var newType = (currentType == medicationTypeMap.keys().size()-1) ? 0 : (currentType+1);
            Properties.setValue("medication"+id+"_type", newType);

            var current_menu = viewStack[viewStack.size()-1] as Menu2;
            (current_menu.getItem(2) as IconMenuItem).setIcon(medicationIconMap[newType]);
            current_menu.getItem(2).setSubLabel(medicationTypeMap[newType]);
            var parent_menu = viewStack[viewStack.size()-2] as Menu2;
            (parent_menu.getItem(id) as IconMenuItem).setIcon(medicationIconMap[newType]);

        } else {

        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
    }
}

class MedicationTrackerDelegate extends WatchUi.BehaviorDelegate {

    //! Constructor
    public function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Handle the back key being pressed
    public function onBack() as Boolean {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
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
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
    }
}
