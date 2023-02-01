import Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Time;

class SelectableNumberDisplay extends WatchUi.Drawable {

    var selected = false;
    var value = 0;
    var font = Graphics.FONT_MEDIUM;
    var identifier = "";
    var locX = 0;
    var locY = 0;
    var width = 0;
    var w = 0;
    var h = 0;
    var x = 0;
    var y = 0;


    function initialize(settings) {
        Drawable.initialize(settings);
        
        font = settings[:font];
        selected = settings[:initialSelectedState];
        identifier = settings[:identifier];
        locX = settings[:locX];
        locY = settings[:locY];
        width = settings[:width];
    }

    function draw(dc as Graphics.Dc) as Void {
        
        var border = 2;
        h = dc.getFontHeight(font) + 2*border;
        w = dc.getFontHeight(font)*0.55*width + 2*border;
        x = locX - (w/2);
        y = locY - (h/2);

        if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawRectangle(x, y, w, h);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.drawRectangle(x+border, y+border, w-2*border, h-2*border);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.drawText(locX, locY, font, value.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function touchIsInside(touchX, touchY) {
        if (touchX >= x and touchX <= x+w and touchY >= y and touchY <= y+h) {
            return true;
        } else {
            return false;
        }
    }
}

class UpDownButton extends WatchUi.Drawable {

    var identifier = "";
    var upNotDown = true;
    var locX = 0;
    var locY = 0;
    var w = 0;
    var h = 0;
    var x = 0;
    var y = 0;

    function initialize(settings) {
        Drawable.initialize(settings);
        
        identifier = settings[:identifier];
        locX = settings[:locX];
        locY = settings[:locY];
        upNotDown = settings[:upNotDown];
    }

    function draw(dc as Graphics.Dc) as Void {
        
        var screenDiagonal = dc.getWidth();
        h = 0.1*screenDiagonal;
        w = 0.2*screenDiagonal;
        x = locX - (w/2);
        y = locY - (h/2);

        if (upNotDown) {
            dc.drawLine(x, y+h, x+(w/2), y);        
            dc.drawLine(x+w, y+h, x+(w/2), y);        
        } else {
            dc.drawLine(x, y, x+(w/2), y+h);        
            dc.drawLine(x+w, y, x+(w/2), y+h);        
        }
    }

    function touchIsInside(touchX, touchY) {
        if (touchX >= x and touchX <= x+w and touchY >= y and touchY <= y+h) {
            return true;
        } else {
            return false;
        }
    }
}

class ValidateButton extends WatchUi.Drawable {

    var identifier = "";
    var button;
    var w = 0;
    var h = 0;
    var x = 0;
    var y = 0;

    function initialize(settings) {
        Drawable.initialize(settings);
        
        identifier = settings[:identifier];
        var locX = settings[:locX];
        var locY = settings[:locY];
        
        button = new WatchUi.Bitmap({:rezId=>settings[:rezId], :locX=>locX, :locY=>locY});
        var dim = button.getDimensions();

        w = dim[0];
        h = dim[1];
        x = locX - (w/2);
        y = locY - (h/2);

        button.setLocation(x, y);
    }

    function draw(dc as Graphics.Dc) as Void {
        button.draw(dc);        
    }

    function touchIsInside(touchX, touchY) {
        if (touchX >= x and touchX <= x+w and touchY >= y and touchY <= y+h) {
            return true;
        } else {
            return false;
        }
    }
}

class TimeAndDatePicker extends WatchUi.View {

    var timeNumberDisplay = {};
    var dateNumberDisplay = {};
    var upButton;
    var downButton;
    var validateButton;

    var timestamp = 1675186833;

    var font = Graphics.FONT_MEDIUM;
    var screenWidth = 0;

    var timeNotDate = true;
    
    function initialize() {
        WatchUi.View.initialize();
    }

    function updateNumberValues() {

        var moment = Time.Gregorian.info(new Time.Moment(timestamp), Time.FORMAT_SHORT);
        timeNumberDisplay["hours"].value = moment.hour;
        timeNumberDisplay["minutes"].value = moment.min;
        timeNumberDisplay["seconds"].value = moment.sec;
        dateNumberDisplay["day"].value = moment.day;
        dateNumberDisplay["month"].value = moment.month;
        dateNumberDisplay["year"].value = moment.year;
    }

    // Resources are loaded here
    function onLayout(dc) {
        var charHight = dc.getFontHeight(font);
        screenWidth = dc.getWidth();

        // Draw the hours, minutes and seconds display zones
        timeNumberDisplay["hours"] = new SelectableNumberDisplay({:initialSelectedState=>true, :font=>font, :identifier=>"hours", :locX=>screenWidth*0.2, :locY=>screenWidth*0.5, :width=>2});
        timeNumberDisplay["minutes"] = new SelectableNumberDisplay({:initialSelectedState=>false, :font=>font, :identifier=>"minutes", :locX=>screenWidth*0.5, :locY=>screenWidth*0.5, :width=>2});
        timeNumberDisplay["seconds"] = new SelectableNumberDisplay({:initialSelectedState=>false, :font=>font, :identifier=>"seconds", :locX=>screenWidth*0.8, :locY=>screenWidth*0.5, :width=>2});
        dateNumberDisplay["day"] = new SelectableNumberDisplay({:initialSelectedState=>true, :font=>font, :identifier=>"day", :locX=>screenWidth*0.15, :locY=>screenWidth*0.5, :width=>2});
        dateNumberDisplay["month"] = new SelectableNumberDisplay({:initialSelectedState=>false, :font=>font, :identifier=>"month", :locX=>screenWidth*0.45, :locY=>screenWidth*0.5, :width=>2});
        dateNumberDisplay["year"] = new SelectableNumberDisplay({:initialSelectedState=>false, :font=>font, :identifier=>"year", :locX=>screenWidth*0.8, :locY=>screenWidth*0.5, :width=>4});
        upButton = new UpDownButton({:identifier=>"up", :upNotDown=>true, :locX=>screenWidth*0.5, :locY=>screenWidth*0.3});
        downButton = new UpDownButton({:identifier=>"down", :upNotDown=>false, :locX=>screenWidth*0.5, :locY=>screenWidth*0.7});
        validateButton = new ValidateButton({:rezId=>$.Rez.Drawables.GreenCheckSmall, :locX=>screenWidth*0.75, :locY=>screenWidth*0.75});
        
        updateNumberValues();
    }

    // onShow() is called when this View is brought to the foreground
    function onShow() {
    }

    // onUpdate() is called periodically to update the View
    function onUpdate(dc) {
        WatchUi.View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        if (timeNotDate) {
            timeNumberDisplay["hours"].draw(dc);
            timeNumberDisplay["minutes"].draw(dc);
            timeNumberDisplay["seconds"].draw(dc);
        } else {
            dateNumberDisplay["day"].draw(dc);
            dateNumberDisplay["month"].draw(dc);
            dateNumberDisplay["year"].draw(dc);
        }

        upButton.draw(dc);
        downButton.draw(dc);
        validateButton.draw(dc);

        if (timeNotDate) {
            dc.drawText(screenWidth*0.35, screenWidth*0.5, font, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(screenWidth*0.65, screenWidth*0.5, font, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.fillRectangle(0, 0, screenWidth, screenWidth*0.2);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.drawText(screenWidth*0.5, screenWidth*0.1, font, "Time", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(screenWidth*0.3, screenWidth*0.5, font, "/", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(screenWidth*0.6, screenWidth*0.5, font, "/", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.fillRectangle(0, 0, screenWidth, screenWidth*0.2);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.drawText(screenWidth*0.5, screenWidth*0.1, font, "Date", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // onHide() is called when this View is removed from the screen
    function onHide() {
    }

    

    function incrementOrDecementCurrentNumber(incrementNotDecrement as Boolean) {

        var increment = {
            "seconds"=>1, 
            "minutes"=>Time.Gregorian.SECONDS_PER_MINUTE,
            "hours"=>Time.Gregorian.SECONDS_PER_HOUR,
            "day"=>Time.Gregorian.SECONDS_PER_DAY,
            "year"=>Time.Gregorian.SECONDS_PER_YEAR
            };

        var numberDisplay = timeNotDate ? timeNumberDisplay : dateNumberDisplay;
        var numberDisplayKeys = numberDisplay.keys();
        for(var i = 0; i < numberDisplayKeys.size(); i++) {
            var currentItem = numberDisplay[numberDisplayKeys[i]];
            if (currentItem.selected) {

                var currentIncrement = 0;
                if (currentItem.identifier.equals("month")) {
                    
                    var moment = Time.Gregorian.info(new Time.Moment(timestamp), Time.FORMAT_SHORT);

                    var month = moment.month;
                    var year = moment.year;
                    var daysInCurrentMonth = Helper.daysInAMonth(month, year);

                    var previousMonth = (month == 1) ? 12 : month-1;
                    var yearOfPreviousMonth = (month == 1) ? year-1 : year;
                    var daysInPreviousMonth = Helper.daysInAMonth(previousMonth, yearOfPreviousMonth);

                    var nextMonth = (month == 12) ? 1 : month+1;
                    var yearOfNextMonth = (month == 12) ? year+1 : year;
                    var daysInNextMonth = Helper.daysInAMonth(nextMonth, yearOfNextMonth);

                    if (incrementNotDecrement) {
                        if (daysInCurrentMonth > daysInNextMonth) {
                            if (moment.day > daysInNextMonth) {
                                currentIncrement = daysInNextMonth * Time.Gregorian.SECONDS_PER_DAY;
                            } else {
                                currentIncrement = daysInCurrentMonth * Time.Gregorian.SECONDS_PER_DAY;
                            }
                        } else {
                            currentIncrement = daysInCurrentMonth * Time.Gregorian.SECONDS_PER_DAY;
                        } 
                    } else {
                        if (daysInCurrentMonth > daysInPreviousMonth) {
                            if (moment.day > daysInPreviousMonth) {
                                currentIncrement = -daysInCurrentMonth * Time.Gregorian.SECONDS_PER_DAY;
                            } else {
                                currentIncrement = -daysInPreviousMonth * Time.Gregorian.SECONDS_PER_DAY;
                            }
                        } else {
                            currentIncrement = -daysInPreviousMonth * Time.Gregorian.SECONDS_PER_DAY;
                        } 
                    }
                } else {
                    if (incrementNotDecrement) {
                        currentIncrement = increment[currentItem.identifier];
                    } else {
                        currentIncrement = -increment[currentItem.identifier];
                    }
                }

                timestamp = timestamp + currentIncrement;
                updateNumberValues();
                break;
            }
        }
    }

    function onTap(clickEvent as WatchUi.ClickEvent) {
        var x = clickEvent.getCoordinates()[0];
        var y = clickEvent.getCoordinates()[1];
        
        var numberDisplay = timeNotDate ? timeNumberDisplay : dateNumberDisplay;
        var numberDisplayKeys = numberDisplay.keys();
        for(var i = 0; i < numberDisplayKeys.size(); i++) {
            var currentItem = numberDisplay[numberDisplayKeys[i]];
            if (currentItem.touchIsInside(x, y)) {
                for(var j = 0; j < numberDisplayKeys.size(); j++) {
                    numberDisplay[numberDisplayKeys[j]].selected = (i == j);
                }
                WatchUi.requestUpdate();
                return;
            }
        }

        if (upButton.touchIsInside(x, y)) {
            incrementOrDecementCurrentNumber(true);
            WatchUi.requestUpdate();
            return;
        }

        if (downButton.touchIsInside(x, y)) {
            incrementOrDecementCurrentNumber(false);            
            WatchUi.requestUpdate();
            return;
        }

        if (validateButton.touchIsInside(x, y)) {
            if (timeNotDate) {
                timeNotDate = false;

            } else {
                // TODO : End of time and date typing
                ViewManager.popView(WatchUi.SLIDE_RIGHT);
            }
            WatchUi.requestUpdate();
            return;
        }
    }

    function onBack() {
        if (!timeNotDate) {
            timeNotDate = true;
            WatchUi.requestUpdate();

        } else {
            ViewManager.popView(WatchUi.SLIDE_RIGHT);
        }        
    }

}

class TimeAndDatePickerDelegate extends WatchUi.InputDelegate {

    var _picker as TimeAndDatePicker;

    function initialize(timePicker) {
        InputDelegate.initialize();
        _picker = timePicker;
    }

    function onKey(keyEvent) {
        if (keyEvent.getKey() == WatchUi.KEY_ESC) {
            _picker.onBack();
        }
        return true;
    }

    function onTap(clickEvent) {
        _picker.onTap(clickEvent);
        return true;
    }

    function onSwipe(swipeEvent) {
        return true;
    }

}