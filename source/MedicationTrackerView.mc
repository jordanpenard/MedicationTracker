import Toybox.Graphics;
import Toybox.WatchUi;


class MedicationTrackerView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        var mainMenu = new WatchUi.Menu2({:title=>"Medication tracker"});

        mainMenu.addItem(new MenuItem("Take medication", null, "take", {}));
        mainMenu.addItem(new MenuItem("History", null, "history", {}));
        mainMenu.addItem(new MenuItem("Settings", null, "settings", {}));
        
        ViewManager.pushView(mainMenu, new MainMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
