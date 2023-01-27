import Toybox.Graphics;
import Toybox.WatchUi;

//! View class for Drawable
class GreenCheckView extends WatchUi.View {

    private var _green_check as Bitmap;

    //! Constructor
    public function initialize() {
        View.initialize();
        _green_check = new WatchUi.Bitmap({:rezId=>$.Rez.Drawables.GreenCheck, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
    }

    //! Load the resources
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        //dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        _green_check.draw(dc);
    }

    //! Restore the state of the app and prepare the view to be shown
    public function onShow() as Void {
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc as Dc) as Void {
    }

}
