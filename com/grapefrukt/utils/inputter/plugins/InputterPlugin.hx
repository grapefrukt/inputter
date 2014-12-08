package com.grapefrukt.utils.inputter.plugins;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */
class InputterPlugin {
	
	var setButton:Int->Bool->Void;
	var setAxis:Int->Float->Void;
	
	public function init(inputter:Inputter, setButton:Int->Bool->Void, setAxis:Int->Float->Void) {
		this.setButton = setButton;
		this.setAxis = setAxis;
	}
	
	public function setVibration(lowFreq:Float, highFreq:Float){
		
	}
}