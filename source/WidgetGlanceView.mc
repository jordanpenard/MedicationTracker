using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
import Toybox.Lang;
import Toybox.Application;
import Toybox.Time;
using Toybox.Time.Gregorian;


(:glance)
class WidgetGlanceView extends Ui.GlanceView {

  function initialize() {
    GlanceView.initialize();
  }

  function onUpdate(dc) {
    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    dc.clear();

    var historyData = Storage.getValue("history_data") as Dictionary<Number, Array<Number>>?;
    var dataToDisplay = [];

    if (historyData != null) {
      for (var i = 0; i < Helper.nbMedications; i++){
        if (Properties.getValue("medication"+i+"_en")) {
          if (historyData.hasKey(i) and historyData[i].size() != 0) {
            var now = new Moment(Time.now().value());
            var date = new Moment(historyData[i][historyData[i].size()-1]);
            var deltaInSeconds = date.subtract(now).value();
            var deltaInHours = deltaInSeconds/3600;
            
            var text = Properties.getValue("medication"+i+"_name") + " : "+deltaInHours.toString()+"h "+Application.loadResource($.Rez.Strings.ago);
            var bitmapSymbole = Helper.getMedicationIconeSymbol(i, true);
            
            dataToDisplay.add([text, bitmapSymbole]);
          }
        }
      }
    }

    var font = Graphics.FONT_XTINY;
    var textHight = dc.getFontHeight(font);

    if (dataToDisplay.size() == 0) {
      dc.drawText(0, (dc.getHeight()-textHight)/2, font, Application.loadResource($.Rez.Strings.no_data_yet), Graphics.TEXT_JUSTIFY_LEFT);
    
    } else {
      var margin = 0;
      if (textHight*dataToDisplay.size() < dc.getHeight()) {
        margin = (dc.getHeight() - textHight*dataToDisplay.size()) / (dataToDisplay.size()+1);
      } 

      var y = 0;
      for (var i = 0; i < dataToDisplay.size(); i++) {
        var text = dataToDisplay[i][0];
        var bitmap = WatchUi.loadResource(dataToDisplay[i][1]);
        dc.drawText(35, y+margin, font, text, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(0, y+margin, bitmap);
        y += margin+textHight;
      }

    }
  }
}