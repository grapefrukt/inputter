package com.grapefrukt.utils.inputter;
import flash.display.Stage;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.Lib;
import flash.utils.Timer;

#if cpp
import openfl.events.JoystickEvent;
#end

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */

class Inputter {
	
	private var plugins:Array<InputterPlugin>;
	public var players(default, null):Array<InputterPlayerData>;
	public var stage(default, null):Stage;
	public var numPlugins(get_numPlugins, never):Int;
	
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
		this.players = new Array<InputterPlayerData>();
		this.plugins = [];
	}
	
	public function add(plugin:InputterPlugin):Int {
		plugin.init(this);
		plugins.push(plugin);
		return plugins.length;
	}
	
	public function registerPlayer(plugin:Int, device:Int, axisX:Int = 0, axisY:Int = 1, primaryButton:Int = 0) {
		players.push(new InputterPlayerData(players.length, plugins[plugin], device, axisX, axisY, primaryButton));
	}
	
	inline public function getMovement(player:Int, out:Point = null):Point {
		return players[player].getMovement(out);
	}
	
	inline public function hasMovement(player:Int):Bool {
		return players[player].hasMovement();
	}
	
	public function isDown(player:Int, button:Int):Bool {
		return players[player].isDown(button);
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
	
	private function get_numPlugins() {
		return plugins.length;
	}
	
}

class InputterPlayerData {
	
	private var plugin:InputterPlugin;
	private var index(default, null):Int;
	private var device(default, null):Int;
	private var axisX:Int;
	private var axisY:Int;
	private var primaryButton:Int;
	
	public function new(index:Int, plugin:InputterPlugin, device:Int, axisX:Int, axisY:Int, primaryButton:Int) {
		this.index = index;
		this.plugin = plugin;
		this.device = device;
		this.axisX = axisX;
		this.axisY = axisY;
		this.primaryButton = primaryButton;
	}
	
	public function getMovement(out:Point = null):Point {
		var d = plugin.data[device];
		return Inputter.applyDeadzone(d.axis[axisX], d.axis[axisY], out != null ? out : Inputter._tmpPoint);
	}
	
	inline public function hasMovement():Bool {
		return getMovement().length > .25;
	}
	
	public function isDown(button:Int = -1):Bool {
		if (button == -1 ) button = primaryButton;
		return plugin.data[device].buttons[button];
	}
}

class InputterData {
	public var axis(default, null):Array<Float>;
	public var buttons(default, null):Array<Bool>;
	
	public function new() {
		axis = new Array<Float>();
		buttons = new Array<Bool>();
	}
}


private class InputterPlugin {

	public var data:Array<InputterData>;
	
	public function new(numDevices:Int, numAxis:Int, numButtons:Int) {
		data = new Array<InputterData>();
		
		// pre inits devices, buttons and axis so they can be read even if no events have been received
		for (i in 0 ... numDevices) {
			for (j in 0 ... numAxis) setAxis(i, j, 0);
			for (j in 0 ... numButtons) setButton(i, j, false);
		}
	}
	
	public function init(inputter:Inputter){}
	
	private function setButton(deviceId:Int, buttonId:Int, state:Bool) {
		if (data[deviceId] == null) initDevice(deviceId);
		data[deviceId].buttons[buttonId] = state;
	}
	
	private function setAxis(deviceId:Int, axisId:Int, value:Float) {
		if (data[deviceId] == null) initDevice(deviceId);
		data[deviceId].axis[axisId] = value;
	}
	
	private function getAxis(deviceId:Int, axisId:Int):Float {
		if (data[deviceId] == null) initDevice(deviceId);
		return data[deviceId].axis[axisId];
	}
	
	private function initDevice(deviceId:Int) {
		data[deviceId] = new InputterData();
	}
}

private typedef KeyboardDeviceMap = {
	device : Int,
	button : Int,
	axis : Int,
	value : Int,
}

class InputterPluginKeyboard extends InputterPlugin {
	
	private var keyMap:Array<KeyboardDeviceMap>;
	
	public function new(numDevices:Int, numAxis:Int, numButtons:Int) {
		super(numDevices, numAxis, numButtons);
		keyMap = new Array<KeyboardDeviceMap>();
	}
	
	override public function init(inputter:Inputter) {
		super.init(inputter);
		inputter.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKey);
		inputter.stage.addEventListener(KeyboardEvent.KEY_UP, handleKey);
	}
	
	/**
	 * Maps keys to controller axis
	 * @param	device		The device to report as
	 * @param	keyCodes	A list of buttons in pairs of minus/plus
	 */
	public function mapAxis(device:Int, keyCodes:Array<Int>) {
		var i = 0;
		var axis = 0;
		while (i < keyCodes.length - 1) {
			keyMap[keyCodes[i + 0]] = { device : device, button : -1, axis : axis, value : -1 };
			keyMap[keyCodes[i + 1]] = { device : device, button : -1, axis : axis, value : 1 };
			axis++;
			i += 2;
		}
	}
	
	public function mapButtons(device:Int, keyCodes:Array<Int>) {
		for (i in 0 ... keyCodes.length) keyMap[keyCodes[i]] =  { device : device, button : i, axis : -1, value : 0 };
	}
	
	private function handleKey(e:KeyboardEvent):Void {
		var key = keyMap[e.keyCode];
		if (key == null) return;
		if (key.axis >= 0) {
			var value = e.type == KeyboardEvent.KEY_DOWN ? key.value : 0;
			if (getAxis(key.device, key.axis) != key.value && value == 0) return;
			setAxis(key.device, key.axis, value);
		}
		if (key.button >= 0) setButton(key.device, key.button, e.type == KeyboardEvent.KEY_DOWN);
	}
}

class InputterPluginFuzzer extends InputterPlugin {
	
	private var numDevices:Int;
	private var numAxis:Int;
	private var numButtons:Int;
	
	private var offsets:Array<Float>;
	private var speeds:Array<Float>;
	
	private var timer:Timer;
	
	public var enabled:Bool;
	
	public function new(numDevices:Int, numAxis:Int, numButtons:Int) {
		super(numDevices, numAxis, numButtons);
		this.numDevices = numDevices;
		this.numAxis = numButtons;
		
		offsets = [];
		speeds = [];
		for ( i in 0 ... numDevices) {
			offsets[i] = Math.random() * Math.PI * 2;
			speeds[i] = .05 + Math.random() * .4;
		}
		
		timer = new Timer(16);
		timer.addEventListener(TimerEvent.TIMER, handleTimer);
		timer.start();
		enabled = false;
	}
	
	private function handleTimer(e:TimerEvent):Void {
		if (!enabled) {
			for (device in 0 ... numDevices) {
				setAxis(device, 0, 0);
				setAxis(device, 1, 0);
				setButton(device, 0, false);
			}
			return;
		}
		
		for (device in 0 ... numDevices) {
			offsets[device] += speeds[device];
			setAxis(device, 0, Math.sin(offsets[device]));
			setAxis(device, 1, Math.cos(offsets[device]));
			setButton(device, 0, Math.sin(offsets[device]) > .5);
			
			if (Math.random() < .025) {
				offsets[device] = Math.random() * Math.PI * 2;
				speeds[device] = .05 + Math.random() * .2 * (Math.random() < .5 ? 1 : -1);
			}
		}
	}
	
}

#if cpp
class InputterPluginJoystick extends InputterPlugin {
	
	private var buttonMap:Array<Int>;
	
	public function new(numDevices:Int, numAxis:Int, numButtons:Int) {
		super(numDevices, numAxis, numButtons);
	}
	
	override public function init(inputter:Inputter) {
		super.init(inputter);
		inputter.stage.addEventListener(JoystickEvent.AXIS_MOVE, handleAxis);
		inputter.stage.addEventListener(JoystickEvent.BUTTON_DOWN, handleButton);
		inputter.stage.addEventListener(JoystickEvent.BUTTON_UP, handleButton);
	}
	
	/**
	 * Remaps button id's
	 * @param	buttonCodes A list of button id's in the order to map them. [3, 4, 5] will map to buttons [0, 1, 2]. If you set a map unmapped buttons will be ignored.
	 */
	public function mapButtons(buttonCodes:Array<Int>) {
		buttonMap = new Array<Int>();
		for (i in 0 ... buttonCodes.length) buttonMap[buttonCodes[i]] = i;
	}
	
	private function handleAxis(e:JoystickEvent):Void {
		for (i in 0 ... e.axis.length) setAxis(e.device, i, e.axis[i]);
	}
	
	private function handleButton(e:JoystickEvent):Void {
		var id = e.id;
		if (buttonMap != null) {
			//if (buttonMap[id] == null) return;
			id = buttonMap[id];
		}
		setButton(e.device, e.id, e.type == JoystickEvent.BUTTON_DOWN);
	}
}
#end