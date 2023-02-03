import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;


//! Factory that controls which characters can be picked
class CharacterFactory extends WatchUi.PickerFactory {
    private var _characterSet as String;
    private var _addOk as Boolean;
    private const DONE = -1;

    //! Constructor
    //! @param characterSet The characters to include in the Picker
    //! @param addOk true to add OK button, false otherwise
    public function initialize(characterSet as String, addOk as Boolean) {
        PickerFactory.initialize();
        _characterSet = characterSet;
        _addOk = addOk;
    }

    //! Get the index of a character item
    //! @param value The character to get the index of
    //! @return The index of the character
    public function getIndex(value as String) as Number? {
        return _characterSet.find(value);
    }

    //! Get the number of picker items
    //! @return Number of items
    public function getSize() as Number {
        return _characterSet.length() + (_addOk ? 1 : 0);
    }

    //! Get the value of the item at the given index
    //! @param index Index of the item to get the value of
    //! @return Value of the item
    public function getValue(index as Number) as Object? {
        if (index == _characterSet.length()) {
            return DONE;
        }

        return _characterSet.substring(index, index + 1);
    }

    //! Generate a Drawable instance for an item
    //! @param index The item index
    //! @param selected true if the current item is selected, false otherwise
    //! @return Drawable for the item
    public function getDrawable(index as Number, selected as Boolean) as Drawable? {
        if (index == _characterSet.length()) {
            return new WatchUi.Text({:text=>$.Rez.Strings.ok, :color=>Graphics.COLOR_WHITE,
                :font=>Graphics.FONT_LARGE, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
        }

        return new WatchUi.Text({:text=>getValue(index) as String, :color=>Graphics.COLOR_WHITE, :font=>Graphics.FONT_LARGE,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
    }

    //! Get whether the user selected OK and is done picking
    //! @param value Value user selected
    //! @return true if user is done, false otherwise
    public function isDone(value as String or Number) as Boolean {
        return _addOk and (value == DONE);
    }
}

//! Picker that allows the user to choose a string
class StringPicker extends WatchUi.Picker {
    private const _characterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private var _curString as String;
    private var _title as Text;
    private var _factory as CharacterFactory;

    //! Constructor
    public function initialize(lastString) {
        _factory = new $.CharacterFactory(_characterSet, true);
        _curString = "";

        var defaults = null;
        var titleText = lastString;

        if (lastString instanceof String) {
            _curString = lastString;
            var startValue = lastString.substring(lastString.length() - 1, lastString.length());
            if (startValue != null) {
                defaults = [_factory.getIndex(startValue)];
            }
        }

        _title = new WatchUi.Text({:text=>titleText, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});

        Picker.initialize({:title=>_title, :pattern=>[_factory], :defaults=>defaults});
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        //dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    //! Add a character to the end of the title
    //! @param character Character to add
    public function addCharacter(character as String) as Void {
        _curString += character;
        _title.setText(_curString);
    }

    //! Remove the last character from the title
    public function removeCharacter() as Void {
        _curString = _curString.substring(0, _curString.length() - 1) as String;

        if (0 == _curString.length()) {
            _title.setText("");
        } else {
            _title.setText(_curString);
        }
    }

    //! Get the title
    //! @return Title string
    public function getTitle() as String {
        return _curString;
    }

    //! Get how long the title is
    //! @return Length of title
    public function getTitleLength() as Number {
        return _curString.length();
    }

    //! Get whether the user is done picking
    //! @param value Value user selected
    //! @return true if user is done, false otherwise
    public function isDone(value as String or Number) as Boolean {
        return _factory.isDone(value);
    }
}

//! Responds to a string picker selection or cancellation
class MedicationNamePickerDelegate extends WatchUi.PickerDelegate {
    private var _picker as StringPicker;
    private var _medicationId as Number;

    private var firstChar = true;

    //! Constructor
    public function initialize(picker as StringPicker, medicationId as Number) {
        PickerDelegate.initialize();
        _picker = picker;
        _medicationId = medicationId;
    }

    //! Handle a cancel event from the picker
    //! @return true if handled, false otherwise
    public function onCancel() as Boolean {
        if (0 == _picker.getTitleLength()) {
            ViewManager.popView(WatchUi.SLIDE_RIGHT);
        } else {
            _picker.removeCharacter();
        }
        return true;
    }

    //! Handle a confirm event from the picker
    //! @param values The values chosen in the picker
    //! @return true if handled, false otherwise
    public function onAccept(values as Array<String>) as Boolean {
        if (!_picker.isDone(values[0])) {
            if (firstChar) {
                while (_picker.getTitleLength() != 0) {
                    _picker.removeCharacter();
                }
                firstChar = false;
            }
            _picker.addCharacter(values[0]);
        } else {
            if (_picker.getTitle().length() != 0) {
                var new_name = _picker.getTitle();
                new_name = new_name.substring(0, 1).toUpper() + new_name.substring(1, null).toLower();
                Properties.setValue("medication"+_medicationId+"_name", new_name);
                var current_menu = viewStack[viewStack.size()-2] as Menu2;
                current_menu.setTitle(new_name);
                current_menu.getItem(0).setSubLabel(new_name);
                var parent_menu = viewStack[viewStack.size()-3] as Menu2;
                parent_menu.getItem(_medicationId+1).setLabel(new_name);
            }
            ViewManager.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

}
