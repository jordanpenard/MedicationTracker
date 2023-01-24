import Toybox.Lang;
import Toybox.WatchUi;


var viewStack = [] as Array<WatchUi.View>;
class ViewManager {

    public function pushView(view as WatchUi.Views, delegate as WatchUi.InputDelegates or Null, transition as WatchUi.SlideType) as Lang.Boolean {
        
        viewStack.add(view);
        return WatchUi.pushView(view, delegate, transition);
    }

    public function popView(transition as WatchUi.SlideType) as Void {

        viewStack = viewStack.slice(0, -1);
        WatchUi.popView(transition);
        WatchUi.requestUpdate();
    }
}