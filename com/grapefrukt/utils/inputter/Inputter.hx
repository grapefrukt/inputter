package com.grapefrukt.utils.inputter;

import haxe.Timer;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.geom.Point;
import openfl.Lib;

#if cpp
import openfl.events.JoystickEvent;
#end

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */

class Inputter {
	
	public var players(default, null):Array<InputterPlayer>;
	public var stage(default, null):Stage;
	
	private static var deadzone:Float;
	private static var upperDeadzone:Float;
	public static var _tmpPoint:Point = new Point();
	
	/**
	 * Creates a new Inputter to manage inputs
	 * @param	stage			A reference to the current Stage, needed to listen for events
	 * @param	deadzone		The lower bound for analog inputs needed to register
	 * @param	upperDeadzone	The upper bound for analog inputs (some controllers give a non regular shape on maxed out inputs)
	 */
	public function new(stage:Stage, deadzone:Float = .2, upperDeadzone:Float = .95) {
		this.stage = stage;
		Inputter.deadzone = deadzone;
		Inputter.upperDeadzone = upperDeadzone;
		this.players = new Array<InputterPlayer>();
	}
	
	public function createPlayer():InputterPlayer {
		var p = new InputterPlayer(this, players.length);
		players.push(p);
		return p;
	}
	
	public static function applyDeadzone(x:Float, y:Float, out:Point):Point {
		out.x = x;
		out.y = y;
		
		if (out.length < deadzone) {
			out.normalize(0);
		} else {
			out.x /= upperDeadzone;
			out.y /= upperDeadzone;
			if (out.length > 1) out.normalize(1);
			
			var scale = (out.length - deadzone) / (1 - deadzone);
			out.x *= scale;
			out.y *= scale;
		}
		
		return out;
	}
	
}

class InputterPlayer extends EventDispatcher {
	
	private var inputter:Inputter;
	private var plugins:Array<InputterPlugin>;
	private var index(default, null):Int;
	
	private var axis(default, null):Array<Float>;
	private var buttons(default, null):Array<Bool>;
		
	public function new(inputter:Inputter, index:Int, numAxis:Int = 5, numButtons:Int = 4) {
		super();
		this.inputter = inputter;
		this.index = index;
		axis = new Array<Float>();
		buttons = new Array<Bool>();
		
		// pre inits devices, buttons and axis so they can be read even if no events have been received
		for (i in 0 ... numAxis) setAxis(i, 0);
		for (i in 0 ... numButtons) setButton(i, false);
	}
	
	public function addPlugin(plugin:InputterPlugin) {
		plugin.init(inputter, setButton, setAxis);
	}
	
	private function setButton(buttonId:Int, state:Bool) {
		if (buttons[buttonId] == state) return;
		buttons[buttonId] = state;
		dispatchEvent(new InputterEvent(state ? InputterEvent.BUTTON_DOWN : InputterEvent.BUTTON_UP, buttonId));
	}
	
	private function setAxis(axisId:Int, value:Float) {
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
	 * @param	button 		the button index to check, defaults to the primary button
	 * @return
	 */
	public function isDown(button:Int = 0):Bool {
		return buttons[button];
	}
}

private class InputterPlugin {
	
	private var setButton:Int->Bool->Void;
	private var setAxis:Int->Float->Void;
	
	public function init(inputter:Inputter, setButton:Int->Bool->Void, setAxis:Int->Float->Void) {
		this.setButton = setButton;
		this.setAxis = setAxis;
	}
}

private typedef KeyboardMap = {
	button : Int,
	axis : Int,
	value : Int,
}

class InputterEvent extends Event {
	
	public static inline var BUTTON_DOWN:String = "inputterevent_button_down";
	public static inline var BUTTON_UP	:String = "inputterevent_button_up";
	
	public var index(default, null):Int;
	
	public function new(type:String, index:Int) {
		super(type, false, false);
		this.index = index;
	}
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

class InputterPluginMouse extends InputterPlugin {
	
	private var p:Point;
	private var stage:Stage;
	
	public var centerRatioX:Float;
	public var centerRatioY:Float;
	public var scaleBy:Float;
	public var clickThreshold:Int = 150;
	
	private var buttonDown:Bool = false;
	private var buttonDownAt:Int = 0;
	private var testInputTarget:MouseEvent -> Bool;
	
	private var timer:Timer;
	
	/**
	 * 
	 * @param	scaleBy				The ratio to scale the mouse position by. Normal values are -.5 to .5 per axis
	 * @param	centerRatioX		The center point to scale the values around
	 * @param	centerRatioY		The center point to scale the values around
	 * @param	testInputTarget		A callback that returns true for a valid input target. Used to ignore inputs on certain elements.
	 */
	public function new(scaleBy:Float = 1, centerRatioX:Float = .5, centerRatioY:Float = .5, testInputTarget:MouseEvent->Bool) {
		this.testInputTarget = testInputTarget;
		this.scaleBy = scaleBy;
		this.centerRatioX = centerRatioX;
		this.centerRatioY = centerRatioY;
		p = new Point();
	}
	
	override public function init(inputter:Inputter, setButton:Int->Bool->Void, setAxis:Int->Float->Void) {
		super.init(inputter, setButton, setAxis);
		stage = inputter.stage;
		
		inputter.stage.addEventListener(MouseEvent.MOUSE_DOWN, handleButton);
		inputter.stage.addEventListener(MouseEvent.MOUSE_UP, handleButton);
		
		inputter.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, handleButtonR);
		inputter.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, handleButtonR);
		
		inputter.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMove);
		
	}

	private function handleButton(e:MouseEvent):Void {
		buttonDown = e.type == MouseEvent.MOUSE_DOWN;
		
		// if there's a callback to test the input target, run it
		// it will return true if the target is valid
		if (buttonDown && testInputTarget != null) {
			buttonDown = testInputTarget(e);
		}
		
		if (buttonDown) {
			// note the time when the button was pressed
			buttonDownAt = Lib.getTimer();
			
			// if a click threshold is set, we need to wait before sending movement
			if (clickThreshold > 0) {
				// make sure any previous timers are stopped
				if (timer != null) timer.stop();
				
				// create a new timer that will fire once the threshold has passed
				timer = new Timer(clickThreshold);
				timer.run = handleCheckClick;
			} else {
				// if not, just send off the movement
				handleMove(e);
			}
			
		} else {
			// if the button was released within the click threshold, it's a click!
			if (Lib.getTimer() - buttonDownAt < clickThreshold) handleClick(e);
			
			setAxis(0, 0);
			setAxis(1, 0);
		}
	}
	
	private function handleClick(e:MouseEvent) {
		setButton(0, true);
		setButton(0, false);
	}
	
	private function handleCheckClick():Void {
		timer.stop();
		if (buttonDown) {
			handleMove(null);
		}
	}
	
	private function handleButtonR(e:MouseEvent):Void {
		setButton(1, e.type == MouseEvent.RIGHT_MOUSE_UP);
	}
	
	private function handleMove(e:MouseEvent):Void {
		if (!buttonDown) return;
		p.x = stage.mouseX / stage.stageWidth - centerRatioX;
		p.y = stage.mouseY / stage.stageHeight - centerRatioY;
		
		p.x *= scaleBy;
		p.y *= scaleBy;
		
		if (p.length > 1) p.normalize(1);
		setAxis(0, p.x);
		setAxis(1, p.y);
	}
}

#if cpp
class InputterPluginJoystick extends InputterPlugin {
	
	private var buttonMap:Map<Int, Int>;
	private var axisMap:Map<Int, Int>;
	
	public function new() {
		
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
	
	private function handleAxis(e:JoystickEvent):Void {
		for (i in 0 ... e.axis.length) {
			var id = i;
			if (axisMap != null) {
				if (!axisMap.exists(id)) return;
				id = axisMap.get(id);
			}
			setAxis(id, e.axis[i]);
		}
	}
	
	private function handleButton(e:JoystickEvent):Void {
		var id = e.id;
		if (buttonMap != null) {
			if (!buttonMap.exists(id)) return;
			id = buttonMap.get(id);
		}
		setButton(id, e.type == JoystickEvent.BUTTON_DOWN);
	}
}
#end