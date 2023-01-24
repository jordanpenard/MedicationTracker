import Toybox.WatchUi;
import Toybox.Lang;

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

}