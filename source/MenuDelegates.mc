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
                menuTitle = $.Rez.Strings.take_med;
            } else {
                menuTitle = $.Rez.Strings.history;
            }

            var menu = new WatchUi.Menu2({:title=>menuTitle});

            for (var i = 0; i < Helper.nbMedications; i++) {
                if (Properties.getValue("medication"+i+"_en")){
                    var bitmap = new WatchUi.Bitmap({:rezId=>Helper.getMedicationIconeSymbol(i, false), :locY=>20});
                    menu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), null, i, bitmap, {}));
                }
            }
            
            if (id.equals("take")) {
                ViewManager.pushView(menu, new TakeMenuDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                ViewManager.pushView(menu, new HistoryMenuDelegate(), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("settings")) {
            var retention = Properties.getValue("retention_length") + " " + Helper.retentionUnitMap(Properties.getValue("retention_unit"));

            var settingsMenu = new WatchUi.Menu2({:title=>$.Rez.Strings.settings});
            settingsMenu.addItem(new MenuItem($.Rez.Strings.keep_data_for, retention, "retention", {}));

            for (var i = 0; i < Helper.nbMedications; i++) {
                var enabled = Properties.getValue("medication"+i+"_en") ? Application.loadResource($.Rez.Strings.enabled) : Application.loadResource($.Rez.Strings.disabled);
                var bitmap = new WatchUi.Bitmap({:rezId=>Helper.getMedicationIconeSymbol(i, false), :locY=>20});
                settingsMenu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), enabled, i, bitmap, {}));
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

    //! Callback for timer
    public function timerCallback() as Void {
        System.exit();
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var medicationId = item.getId() as Number;

        var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
        var timestamp = Time.now().value();

        if (historyData == null) {
            historyData = {medicationId=>[timestamp]};
        } else if (historyData[medicationId] == null) {
            historyData[medicationId] = [timestamp];
        } else {
            historyData[medicationId].add(timestamp);
        }

        // Flush old data out of the database
        var retentionUnitMap = {0=>7*Gregorian.SECONDS_PER_DAY,
                                1=>31*Gregorian.SECONDS_PER_DAY,
                                2=>Gregorian.SECONDS_PER_YEAR};
        var retention = Properties.getValue("retention_length") * retentionUnitMap[Properties.getValue("retention_unit")];
        var retentionLimit = Time.now().subtract(new Time.Duration(retention)).value();
        for (var i = 1; i <= Helper.nbMedications; i++) {
            if (historyData[i] != null) {
                for (var j = historyData[i].size()-1; j >= 0; j--) {
                    if (historyData[i][j] < retentionLimit) {
                        historyData[i] = historyData[i].slice(j+1, historyData[i].size());
                    }
                }
            }
        }

        Storage.setValue("history_data", historyData);

        var greenCheckView = new GreenCheckView();
        ViewManager.pushView(greenCheckView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_BLINK);

        // Closing the app automaticaly after 1sec of showing the green check image after a med has been taken
        var exitAppTimeout = new Timer.Timer();
        exitAppTimeout.start(method(:timerCallback), 1000, false);
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
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
        var medicationId = item.getId() as Number;
        var historyMenu = new WatchUi.Menu2({:title=>Properties.getValue("medication"+medicationId+"_name")});

        Helper.populateHistoryMenu(historyMenu, medicationId);
        ViewManager.pushView(historyMenu, new DatapointDelegate(medicationId), WatchUi.SLIDE_LEFT);
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
            
            medicationSettingMenu.addItem(new MenuItem(Application.loadResource($.Rez.Strings.name), Properties.getValue("medication"+id+"_name"), ["name", id], {}));
            medicationSettingMenu.addItem(new ToggleMenuItem(Application.loadResource($.Rez.Strings.status), {:enabled=>Application.loadResource($.Rez.Strings.enabled), :disabled=>Application.loadResource($.Rez.Strings.disabled)}, ["status", id], enabled, {}));
            
            var bitmap = new WatchUi.Bitmap({:rezId=>Helper.getMedicationIconeSymbol(id.toNumber(), false), :locY=>20});
            medicationSettingMenu.addItem(new IconMenuItem(Application.loadResource($.Rez.Strings.type), Helper.medicationTypeMap(Properties.getValue("medication"+id+"_type")), ["type", id], bitmap, {}));
            
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
        var identifier = item.getId() as Array<String or Number>;
        var action = identifier[0] as String;
        var id = identifier[1] as Number;

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
            parent_menu.getItem(id+1).setSubLabel(!currentStatus ? Application.loadResource($.Rez.Strings.enabled) : Application.loadResource($.Rez.Strings.disabled));

        } else if (action.equals("type")) {
            var currentType = Properties.getValue("medication"+id+"_type") as Number;
            var newType = (currentType == Helper.nbMedicationType-1) ? 0 : (currentType+1);
            Properties.setValue("medication"+id+"_type", newType);

            var bitmap = new WatchUi.Bitmap({:rezId=>Helper.getMedicationIconeSymbol(id, false), :locY=>20});
            var current_menu = viewStack[viewStack.size()-1] as Menu2;
            (current_menu.getItem(2) as IconMenuItem).setIcon(bitmap);
            current_menu.getItem(2).setSubLabel(Helper.medicationTypeMap(newType));
            var parent_menu = viewStack[viewStack.size()-2] as Menu2;
            (parent_menu.getItem(id+1) as IconMenuItem).setIcon(bitmap);

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

class DatapointDelegate extends WatchUi.Menu2InputDelegate {
    var _medication_id as Number;

    //! Constructor
    public function initialize(medication_id) {
        Menu2InputDelegate.initialize();
        _medication_id = medication_id;
    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var datapointIndex = item.getId() as Number;

        if (datapointIndex != -1) {
            var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
            var timestamp = new Time.Moment(historyData[_medication_id][datapointIndex] as Number);
            var dateString = Helper.formatTimestamp(timestamp);

            var datapointMenu = new WatchUi.Menu2({:title=>dateString});
            
            datapointMenu.addItem(new MenuItem(Application.loadResource($.Rez.Strings.edit), null, "edit", {}));
            datapointMenu.addItem(new MenuItem(Application.loadResource($.Rez.Strings.delete), null, "delete", {}));
            
            ViewManager.pushView(datapointMenu, new datapointEditMenuDelegate(_medication_id, datapointIndex), WatchUi.SLIDE_LEFT);
        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
    }
}

class datapointEditMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _medication_id as Number;
    var _datapoint_index as Number;

    //! Constructor
    public function initialize(medication_id, datapoint_index) {
        Menu2InputDelegate.initialize();
        _medication_id = medication_id;
        _datapoint_index = datapoint_index;
    }

    public function timeAndDateEditDone(newTimestamp as Number) as Void {

        var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
        var nbOfDatapoints = historyData[_medication_id].size();

        var oldTimestamp = historyData[_medication_id][_datapoint_index];
        var oldMoment = Time.Gregorian.info(new Time.Moment(oldTimestamp), Time.FORMAT_SHORT);

        // Delete the old point from the array and search where the new one should go to maintain the correct ordering in time
        historyData[_medication_id].remove(oldTimestamp);
        var indexForNewTimestamp = 0;
        for (var i = historyData[_medication_id].size()-1; i >= 0; i--) {
            if (historyData[_medication_id][i] < newTimestamp) {
                indexForNewTimestamp = i + 1;
                break;
            }
        }

        // Add an entry to the array
        historyData[_medication_id].add(newTimestamp);

        // Insert the new timestamp at the "indexForNewTimestamp" location
        for (var i = historyData[_medication_id].size()-1; i > indexForNewTimestamp; i--) {
            historyData[_medication_id][i] = historyData[_medication_id][i-1];
        }
        historyData[_medication_id][indexForNewTimestamp] = newTimestamp;

        Storage.setValue("history_data", historyData);

        var current_menu = viewStack[viewStack.size()-2] as Menu2;
        current_menu.setTitle(Helper.formatTimestamp(new Moment(newTimestamp)));

        var parent_menu = viewStack[viewStack.size()-3] as Menu2;
        for (var i = 0; i < nbOfDatapoints; i++) {
            parent_menu.deleteItem(0);
        }
        Helper.populateHistoryMenu(parent_menu, _medication_id);

    }

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var action = item.getId() as String;

        var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
        var datapoint = historyData[_medication_id][_datapoint_index];
        
        if (action.equals("edit")) {
            var picker = new TimeAndDatePicker(datapoint, method(:timeAndDateEditDone));
            ViewManager.pushView(picker, new TimeAndDatePickerDelegate(picker), WatchUi.SLIDE_LEFT);

        } else if (action.equals("delete")) {
            var nbOfDatapoints = historyData[_medication_id].size();

            historyData[_medication_id].remove(datapoint);
            Storage.setValue("history_data", historyData);

            var parent_menu = viewStack[viewStack.size()-2] as Menu2;
            for (var i = 0; i < nbOfDatapoints; i++) {
                parent_menu.deleteItem(0);
            }
            Helper.populateHistoryMenu(parent_menu, _medication_id);
            ViewManager.popView(WatchUi.SLIDE_RIGHT);
            WatchUi.requestUpdate();

        } else {

        }
    }

    //! Handle the back key being pressed
    public function onBack() as Void {
        ViewManager.popView(WatchUi.SLIDE_RIGHT);
    }
}
