import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

//! Factory that controls which words can be picked
class WordFactory extends WatchUi.PickerFactory {
    private var _words as Array<Symbol>;
    private var _font as FontDefinition;

    //! Constructor
    //! @param words Resource identifiers for strings
    //! @param options Dictionary of options
    //! @option options :font The font to use
    public function initialize(words as Array<Symbol>, options as {:font as FontDefinition}) {
        PickerFactory.initialize();

        _words = words;

        var font = options.get(:font);
        if (font != null) {
            _font = font;
        } else {
            _font = Graphics.FONT_LARGE;
        }
    }

    //! Get the index of an item
    //! @param value The string or resource identifier to get the index of
    //! @return The index
    public function getIndex(value as String or Symbol) as Number {
        if (value instanceof String) {
            for (var i = 0; i < _words.size(); i++) {
                if (value.equals(WatchUi.loadResource(_words[i]))) {
                    return i;
                }
            }
        } else {
            for (var i = 0; i < _words.size(); i++) {
                if (_words[i].equals(value)) {
                    return i;
                }
            }
        }

        return 0;
    }

    //! Get the number of picker items
    //! @return Number of items
    public function getSize() as Number {
        return _words.size();
    }

    //! Get the value of the item at the given index
    //! @param index Index of the item to get the value of
    //! @return Value of the item
    public function getValue(index as Number) as Object? {
        return index;
    }

    //! Generate a Drawable instance for an item
    //! @param index The item index
    //! @param selected true if the current item is selected, false otherwise
    //! @return Drawable for the item
    public function getDrawable(index as Number, selected as Boolean) as Drawable? {
        return new WatchUi.Text({:text=>_words[index], :color=>Graphics.COLOR_WHITE, :font=>_font,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
    }
}

//! Factory that controls which numbers can be picked
class NumberFactory extends WatchUi.PickerFactory {
    private var _start as Number;
    private var _stop as Number;
    private var _increment as Number;
    private var _formatString as String;
    private var _font as FontDefinition;

    //! Constructor
    //! @param start Number to start with
    //! @param stop Number to end with
    //! @param increment How far apart the numbers should be
    //! @param options Dictionary of options
    //! @option options :font The font to use
    //! @option options :format The number format to display
    public function initialize(start as Number, stop as Number, increment as Number, options as {
        :font as FontDefinition,
        :format as String
    }) {
        PickerFactory.initialize();

        _start = start;
        _stop = stop;
        _increment = increment;

        var format = options.get(:format);
        if (format != null) {
            _formatString = format;
        } else {
            _formatString = "%d";
        }

        var font = options.get(:font);
        if (font != null) {
            _font = font;
        } else {
            _font = Graphics.FONT_NUMBER_HOT;
        }
    }

    //! Get the index of a number item
    //! @param value The number to get the index of
    //! @return The index of the number
    public function getIndex(value as Number) as Number {
        return (value / _increment) - _start;
    }

    //! Generate a Drawable instance for an item
    //! @param index The item index
    //! @param selected true if the current item is selected, false otherwise
    //! @return Drawable for the item
    public function getDrawable(index as Number, selected as Boolean) as Drawable? {
        var value = getValue(index);
        var text = "No item";
        if (value instanceof Number) {
            text = value.format(_formatString);
        }
        return new WatchUi.Text({:text=>text, :color=>Graphics.COLOR_WHITE, :font=>_font,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
    }

    //! Get the value of the item at the given index
    //! @param index Index of the item to get the value of
    //! @return Value of the item
    public function getValue(index as Number) as Object? {
        return _start + (index * _increment);
    }

    //! Get the number of picker items
    //! @return Number of items
    public function getSize() as Number {
        return (_stop - _start) / _increment + 1;
    }

}

//! Main picker that shows all the other pickers
class RetentionPicker extends WatchUi.Picker {

    //! Constructor
    public function initialize() {
        var title = new WatchUi.Text({:text=>"Retention", :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        var numberFactory = new $.NumberFactory(1, 9, 1, {:font=>Graphics.FONT_MEDIUM});
        var unitFactory = new $.WordFactory(["Week", "Month", "Year"], {:font=>Graphics.FONT_MEDIUM});
        Picker.initialize({:title=>title, :pattern=>[numberFactory, unitFactory], :defaults=>[Properties.getValue("retention_length")-1, Properties.getValue("retention_unit")]});
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}

//! Responds to a picker selection or cancellation
class RetentionPickerDelegate extends WatchUi.PickerDelegate {

    //! Constructor
    public function initialize() {
        PickerDelegate.initialize();
    }

    //! Handle a cancel event from the picker
    //! @return true if handled, false otherwise
    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    //! When a user selects a picker, start that picker
    //! @param values The values chosen in the picker
    //! @return true if handled, false otherwise
    public function onAccept(values as Array) as Boolean {
        Properties.setValue("retention_length", values[0]);
        Properties.setValue("retention_unit", values[1]);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

}
