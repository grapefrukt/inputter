package com.grapefrukt.utils.inputter;
import com.grapefrukt.utils.inputter.events.InputterEvent;
import com.grapefrukt.utils.inputter.plugins.InputterPlugin;
import openfl.events.EventDispatcher;
import openfl.geom.Point;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */
class InputterPlayer extends EventDispatcher {
	
	var inputter:Inputter;
	var plugins:Array<InputterPlugin>;
	var index(default, null):Int;
	
	var axis(default, null):Array<Float>;
	var buttons(default, null):Array<Bool>;
	
	/**
	 * Sets the amount of low frequency vibration for any plugins that support this. Range 0.0 to 1.0
	 */
	public var vibrateLowFreq(get, set):Float;
	
	/**
	 * Sets the amount of high frequency vibration for any plugins that support this. Range 0.0 to 1.0
	 */
	public var vibrateHighFreq(get, set):Float;
	
	var _vibrateLowFreq:Float = 0;
	var _vibrateHighFreq:Float = 0;
	
	/**
	 * Creates a new Player, it's recommended to use Inputter.createPlayer() instead.
	 * @param	inputter	A reference to an Inputter instance
	 * @param	index		The index of this player (for convenience)
	 * @param	numAxis		The number of axis this player will use
	 * @param	numButtons	The number of buttons this player will use
	 */
	public function new(inputter:Inputter, index:Int, numAxis:Int = 5, numButtons:Int = 4) {
		super();
		this.inputter = inputter;
		this.index = index;
		
		plugins = [];
		
		axis = new Array<Float>();
		buttons = new Array<Bool>();
		
		// pre inits devices, buttons and axis so they can be read even if no events have been received
		for (i in 0 ... numAxis) setAxis(i, 0);
		for (i in 0 ... numButtons) setButton(i, false);
	}
	
	/**
	 * Adds a plugin to this player
	 * @param	plugin	The plugin you want to add
	 */
	public function addPlugin(plugin:InputterPlugin) {
		plugin.init(inputter, setButton, setAxis);
		plugins.push(plugin);
	}
	
	function setButton(buttonId:Int, state:Bool) {
		if (buttons[buttonId] == state) return;
		buttons[buttonId] = state;
		dispatchEvent(new InputterEvent(state ? InputterEvent.BUTTON_DOWN : InputterEvent.BUTTON_UP, buttonId));
	}
	
	function setAxis(axisId:Int, value:Float) {
		axis[axisId] = value;
	}
	
	/**
	 * Returns a deadzoned direction vector
	 * @param	out		The point to output data into, a temporary point will be returned if nothing is supplied (do not retain a reference to this, it will be reused)
	 * @param	axisX	The axis index to use as the x axis
	 * @param	axisY	The axis index to use as the y axis
	 * @return	A normalized direction vector
	 */
	public function getMovement(out:Point = null, axisX:Int = 0, axisY:Int = 1):Point {
		return Inputter.applyDeadzone(axis[axisX], axis[axisY], out != null ? out : Inputter._tmpPoint);
	}
	
	/**
	 * Returns the raw axis value for a particular axis
	 * @param	index	The axis index
	 * @return
	 */
	public function getAxis(index:Int):Float {
		return axis[index];
	}
	
	/**
	 * Returns true if the players directional input along the default axis exceeds the threshold value
	 * @param	threshold	The threshold value to exceed, defaults to 25%
	 * @return
	 */
	inline public function hasMovement(threshold:Float = .25):Bool {
		return getMovement().length > threshold; 
	}
	
	/**
	 * Checks if the player is pressing a button
	 * @param	button 		the button index to check, defaults to the primary button (0)
	 * @return
	 */
	public function isDown(button:Int = 0):Bool {
		return buttons[button];
	}
	
	function updateVibration(){
		if (_vibrateLowFreq < 0) _vibrateLowFreq = 0;
		if (_vibrateLowFreq > 1) _vibrateLowFreq = 1;
		if (_vibrateHighFreq < 0) _vibrateHighFreq = 0;
		if (_vibrateHighFreq > 1) _vibrateHighFreq = 1;
		
		for (plugin in plugins) plugin.setVibration(_vibrateLowFreq, _vibrateHighFreq);
	}
	
	function get_vibrateLowFreq() return _vibrateLowFreq;
	function set_vibrateLowFreq(value:Float) {
		if (_vibrateLowFreq == value) return value;
		_vibrateLowFreq = value;
		updateVibration();
		return _vibrateLowFreq;
	}
	
	function get_vibrateHighFreq() return _vibrateHighFreq;
	function set_vibrateHighFreq(value:Float) {
		if (_vibrateHighFreq == value) return value;
		_vibrateHighFreq = value;
		updateVibration();
		return _vibrateHighFreq;
	}
	
}