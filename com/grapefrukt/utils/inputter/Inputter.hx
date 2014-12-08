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
	
	/**
	 * Creates a player and hooks it up to this Inputter instance
	 * @param	numAxis		The number of axis this player will use
	 * @param	numButtons	The number of buttons this player will use
	 * @return A reference to a new Player instance
	 */
	public function createPlayer(numAxis:Int = 6, numButtons:Int = 10):InputterPlayer {
		var p = new InputterPlayer(this, players.length, numAxis, numButtons);
		players.push(p);
		return p;
	}
	
	/**
	 * Applies deadzone to a pair of inputs
	 * @param	x
	 * @param	y
	 * @param	out
	 * @return
	 */
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