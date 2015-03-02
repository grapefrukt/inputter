package com.grapefrukt.utils.inputter.plugins;
import openfl.events.JoystickEvent;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */
class InputterPluginJoystick extends InputterPlugin {
	
	private var buttonMap:Map<Int, Int>;
	private var axisMap:Map<Int, Int>;
	private var deviceId:Int;
	
	public function new(deviceId:Int, axisCodes:Array<Int> = null, buttonCodes:Array<Int> = null) {
		this.deviceId = deviceId;
		if (axisCodes != null) mapAxis(axisCodes);
		if (buttonCodes != null) mapButtons(buttonCodes);
	}
	
	override public function init(inputter:Inputter, setButton:Int->Bool->Void, setAxis:Int->Float->Void) {
		super.init(inputter, setButton, setAxis);
		inputter.stage.addEventListener(JoystickEvent.AXIS_MOVE, handleAxis);
		inputter.stage.addEventListener(JoystickEvent.BUTTON_DOWN, handleButton);
		inputter.stage.addEventListener(JoystickEvent.BUTTON_UP, handleButton);
	}
	
	/**
	 * Remaps button id's
	 * @param	buttonCodes A list of button id's in the order to map them. [3, 4, 5] will map to buttons [0, 1, 2]. If you set a map unmapped buttons will be ignored.
	 */
	public function mapButtons(buttonCodes:Array<Int>) {
		buttonMap = new Map();
		for (i in 0 ... buttonCodes.length) buttonMap.set(buttonCodes[i], i);
	}
	
	/**
	 * Remaps axis id's
	 * @param	buttonCodes A list of axis id's in the order to map them. [3, 4, 5] will map to axis [0, 1, 2]. If you set a map unmapped axis will be ignored.
	 */
	public function mapAxis(axisCodes:Array<Int>) {
		axisMap = new Map();
		for (i in 0 ... axisCodes.length) axisMap.set(axisCodes[i], i);
	}
	
	function handleAxis(e:JoystickEvent):Void {
		if (e.device != deviceId) return;
		for (i in 0 ... e.axis.length) {
			var id = i;
			if (axisMap != null) {
				if (!axisMap.exists(id)) continue;
				id = axisMap.get(id);
			}
			setAxis(id, e.axis[i]);
		}
	}
	
	function handleButton(e:JoystickEvent) {
		if (e.device != deviceId) return;
		var id = e.id;
		if (buttonMap != null) {
			if (!buttonMap.exists(id)) return;
			id = buttonMap.get(id);
		}
		setButton(id, e.type == JoystickEvent.BUTTON_DOWN);
	}
}