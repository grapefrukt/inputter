package com.grapefrukt.utils.inputter.plugins;

import com.grapefrukt.utils.inputter.plugins.InputterPluginJoystick;

/**
 * This class requires https://github.com/furusystems/openfl-xinput to be installed and linked to your project
 * On platforms other than windows this will fall back to be a plain InputterJoystick instance (ignoring the pollFrequency)
 * @author Martin Jonasson, m@grapefrukt.com
 */

#if !windows 

class InputterPluginJoystickXInput extends InputterPluginJoystick {
	public function new(deviceId:Int, pollFrequency:Int = -1){
		super(deviceId);
	}
}

#else

import haxe.Timer;
import openfl.events.Event;
import com.furusystems.openfl.input.xinput.XBox360Controller;
import com.furusystems.openfl.input.xinput.XBox360ThumbStick;
 
class InputterPluginJoystickXInput extends InputterPluginJoystick {
	
	var pollFrequency:Int;
	var controller:XBox360Controller;

	/**
	 * @param	deviceId		The device id to listen to
	 * @param	pollFrequency	The frequency to poll the controller at (in milliseconds). -1 will match framerate.
	 */
	public function new(deviceId:Int = 0, pollFrequency:Int = -1) {
		super(deviceId);
		this.pollFrequency = pollFrequency;
		
		mapAxis([for (i in 0 ... 6) i]);
		mapButtons([for (i in 0 ... 10) i]);
	}
	
	override public function init(inputter:Inputter, setButton:Int->Bool->Void, setAxis:Int->Float->Void) {
		this.setButton = setButton;
		this.setAxis = setAxis;
		
		controller = new XBox360Controller(deviceId);
		
		if (pollFrequency == -1){
			inputter.stage.addEventListener(Event.ENTER_FRAME, function(e:Event) { poll(); } );
		} else {
			new Timer(pollFrequency).run = poll;
		}
	}
	
	override public function setVibration(lowFreq:Float, highFreq:Float) {
		if (!controller.isConnected()) return;
		controller.setVibration(Std.int(lowFreq * XBox360Controller.MAX_VIBRATION_STRENGTH), Std.int(highFreq * XBox360Controller.MAX_VIBRATION_STRENGTH));
	}
	
	function poll() {
		controller.poll();
		if (!controller.isConnected()) return;
		
		if (axisMap.exists(0)) setAxis(axisMap.get(0), controller.leftStick.xRaw / XBox360ThumbStick.STICK_MAX_MAG);
		if (axisMap.exists(1)) setAxis(axisMap.get(1), -controller.leftStick.yRaw / XBox360ThumbStick.STICK_MAX_MAG);
		if (axisMap.exists(2)) setAxis(axisMap.get(2), controller.rightStick.xRaw / XBox360ThumbStick.STICK_MAX_MAG);
		if (axisMap.exists(3)) setAxis(axisMap.get(3), -controller.rightStick.yRaw / XBox360ThumbStick.STICK_MAX_MAG);
		if (axisMap.exists(4)) setAxis(axisMap.get(4), controller.leftTrigger / XBox360Controller.TRIGGER_MAX_MAG);
		if (axisMap.exists(5)) setAxis(axisMap.get(5), controller.rightTrigger / XBox360Controller.TRIGGER_MAX_MAG);
		
		if (buttonMap.exists(0)) setButton(buttonMap.get(0), controller.a.isDown);
		if (buttonMap.exists(1)) setButton(buttonMap.get(1), controller.b.isDown);
		if (buttonMap.exists(2)) setButton(buttonMap.get(2), controller.x.isDown);
		if (buttonMap.exists(3)) setButton(buttonMap.get(3), controller.y.isDown);
		if (buttonMap.exists(4)) setButton(buttonMap.get(4), controller.leftBumper.isDown);
		if (buttonMap.exists(5)) setButton(buttonMap.get(5), controller.rightBumper.isDown);
		if (buttonMap.exists(6)) setButton(buttonMap.get(6), controller.back.isDown);
		if (buttonMap.exists(7)) setButton(buttonMap.get(7), controller.start.isDown);
		if (buttonMap.exists(8)) setButton(buttonMap.get(8), controller.leftThumbButton.isDown);
		if (buttonMap.exists(9)) setButton(buttonMap.get(9), controller.rightThumbButton.isDown);
	}
}

#end