package com.grapefrukt.utils.inputter.events;
import openfl.events.Event;

/**
 * ...
 * @author Martin Jonasson, m@grapefrukt.com
 */

class InputterEvent extends Event {
	
	public static inline var BUTTON_DOWN:String = "inputterevent_button_down";
	public static inline var BUTTON_UP	:String = "inputterevent_button_up";
	
	public var index(default, null):Int;
	
	public function new(type:String, index:Int) {
		super(type, false, false);
		this.index = index;
	}
}