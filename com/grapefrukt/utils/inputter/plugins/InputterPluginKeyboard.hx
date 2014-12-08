package com.grapefrukt.utils.inputter.plugins;
import openfl.events.KeyboardEvent;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */

private typedef KeyboardMap = {
	button : Int,
	axis : Int,
	value : Int,
}

class InputterPluginKeyboard extends InputterPlugin {
	
	private var keyMap:Array<KeyboardMap>;
	
	public function new() {
		keyMap = new Array<KeyboardMap>();
	}
	
	override public function init(inputter:Inputter, setButton:Int->Bool->Void, setAxis:Int->Float->Void) {
		super.init(inputter, setButton, setAxis);
		inputter.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKey);
		inputter.stage.addEventListener(KeyboardEvent.KEY_UP, handleKey);
	}
	
	/**
	 * Maps keys to controller axis
	 * @param	device		The device to report as
	 * @param	keyCodes	A list of buttons in pairs of minus/plus
	 */
	public function mapAxis(keyCodes:Array<Int>) {
		var i = 0;
		var axis = 0;
		while (i < keyCodes.length - 1) {
			keyMap[keyCodes[i + 0]] = { button : -1, axis : axis, value : -1 };
			keyMap[keyCodes[i + 1]] = { button : -1, axis : axis, value : 1 };
			axis++;
			i += 2;
		}
	}
	
	public function mapButtons(keyCodes:Array<Int>) {
		for (i in 0 ... keyCodes.length) keyMap[keyCodes[i]] =  { button : i, axis : -1, value : 0 };
	}
	
	private function handleKey(e:KeyboardEvent):Void {
		var key = keyMap[e.keyCode];
		if (key == null) return;
		if (key.axis >= 0) {
			var value = e.type == KeyboardEvent.KEY_DOWN ? key.value : 0;
			// TODO: check if this is still needed
			//if (getAxis(key.axis) != key.value && value == 0) return;
			setAxis(key.axis, value);
		}
		if (key.button >= 0) setButton(key.button, e.type == KeyboardEvent.KEY_DOWN);
	}
}