package;

import Song.SwagSong;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	public static var camBeat:FlxCamera;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		camBeat = FlxG.camera;

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if (!skip) openSubState(new CustomFadeTransition(.7, true));
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0) stepHit();
			if (oldStep < curStep) { updateSection(); }
			else { rollbackSection(); }
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;

			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;

		curSection = 0;
		stepsToDo = 0;

		if (PlayState.SONG != null)
		{
			for (i in 0...PlayState.SONG.notes.length)
			{
				if (PlayState.SONG.notes[i] != null)
				{
					stepsToDo += Math.round(getBeatsOnSection() * 4);
					if (stepsToDo > curStep) break;

					curSection++;
				}
			}
		}
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit:Float = ((Conductor.songPosition - ClientPrefs.getPref('noteOffset')) - lastChange.songTime) / lastChange.stepCrochet;

		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;

		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(.6, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;

		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		var song:SwagSong = PlayState.SONG;

		if (song != null && song.notes[curSection] != null) val = song.notes[curSection].sectionBeats;
		return val != null ? val : 4;
	}
}