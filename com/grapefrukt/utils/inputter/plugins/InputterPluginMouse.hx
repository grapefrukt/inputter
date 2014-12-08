package com.grapefrukt.utils.inputter.plugins;
import haxe.Timer;
import openfl.display.Stage;
import openfl.events.MouseEvent;
import openfl.geom.Point;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */
class InputterPluginMouse extends InputterPlugin {
	
	var p:Point;
	var stage:Stage;
	
	public var centerRatioX:Float;
	public var centerRatioY:Float;
	public var scaleBy:Float;
	public var clickThreshold:Int = 150;
	public var holdThreshold:Int = 300;
	
	var buttonDown:Bool = false;
	var buttonDownAt:Int = 0;
	var testInputTarget:MouseEvent -> Bool;
	
	var clickTimer:Timer;
	var holdTimer:Timer;
	
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

	 function handleButton(e:MouseEvent) {
		buttonDown = e.type == MouseEvent.MOUSE_DOWN;
		
		// if there's a callback to test the input target, run it
		// it will return true if the target is valid
		if (buttonDown && testInputTarget != null) {
			buttonDown = testInputTarget(e);
		}
		
		if (buttonDown) {
			// note the time when the button was pressed
			buttonDownAt = Lib.getTimer();
			
			if (holdTimer != null) holdTimer.stop();
			holdTimer = new Timer(holdThreshold);
			holdTimer.run = handleCheckHold;
			
			// if a click threshold is set, we need to wait before sending movement
			if (clickThreshold > 0) {
				// make sure any previous timers are stopped
				if (clickTimer != null) clickTimer.stop();
				
				// create a new timer that will fire once the threshold has passed
				clickTimer = new Timer(clickThreshold);
				clickTimer.run = handleCheckClick;
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
	
	function handleClick(e:MouseEvent) {
		setButton(0, true);
		setButton(0, false);
	}
	
	function handleCheckClick() {
		clickTimer.stop();
		if (buttonDown) {
			handleMove(null);
		}
	}
	
	 function handleCheckHold() {
		holdTimer.stop();
		if (buttonDown) {
			trace("HOLD!");
			setButton(1, true);
			setButton(1, false);
		}
	}
	
	function handleButtonR(e:MouseEvent) {
		setButton(1, e.type == MouseEvent.RIGHT_MOUSE_UP);
	}
	
	function handleMove(e:MouseEvent) {
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