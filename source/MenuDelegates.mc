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

            for (var i = 1; i <= 5; i++) {
                if (Properties.getValue("medication"+i+"_en")){
                    menu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), null, i, Helper.medicationIconMap(Properties.getValue("medication"+i+"_type")), {}));
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

            for (var i = 1; i <= 5; i++) {
                var enabled = Properties.getValue("medication"+i+"_en") ? Application.loadResource($.Rez.Strings.enabled) : Application.loadResource($.Rez.Strings.disabled);
                settingsMenu.addItem(new IconMenuItem(Properties.getValue("medication"+i+"_name"), enabled, i, Helper.medicationIconMap(Properties.getValue("medication"+i+"_type")), {}));
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

        var message = Application.loadResource($.Rez.Strings.take)+" "+Properties.getValue("medication"+id+"_name")+"?";
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
        var medicationId = item.getId() as Integer;
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
            medicationSettingMenu.addItem(new IconMenuItem(Application.loadResource($.Rez.Strings.type), Helper.medicationTypeMap(Properties.getValue("medication"+id+"_type")), ["type", id], Helper.medicationIconMap(Properties.getValue("medication"+id+"_type")), {}));
            
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
            parent_menu.getItem(id).setSubLabel(!currentStatus ? Application.loadResource($.Rez.Strings.enabled) : Application.loadResource($.Rez.Strings.disabled));

        } else if (action.equals("type")) {
            var currentType = Properties.getValue("medication"+id+"_type") as Number;
            var newType = (currentType == Helper.nbMedicationType-1) ? 0 : (currentType+1);
            Properties.setValue("medication"+id+"_type", newType);

            var current_menu = viewStack[viewStack.size()-1] as Menu2;
            (current_menu.getItem(2) as IconMenuItem).setIcon(Helper.medicationIconMap(newType));
            current_menu.getItem(2).setSubLabel(Helper.medicationTypeMap(newType));
            var parent_menu = viewStack[viewStack.size()-2] as Menu2;
            (parent_menu.getItem(id) as IconMenuItem).setIcon(Helper.medicationIconMap(newType));

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

    //! Handle an item being selected
    //! @param item The selected menu item
    public function onSelect(item as MenuItem) as Void {
        var action = item.getId() as String;

        if (action.equals("edit")) {
            ViewManager.pushView(
                new DateAndTimePicker(_medication_id, _datapoint_index),
                new DateAndTimePickerDelegate(_medication_id, _datapoint_index),
                WatchUi.SLIDE_LEFT
            );

        } else if (action.equals("delete")) {
            var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
            var datapoint = historyData[_medication_id][_datapoint_index];
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
