package;

import Section.SwagSection;
import Song.SwagSong;

/**
 * ...
 * @author
 */
typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = calculateCrochet(bpm); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var safeZone:Float = (ClientPrefs.getPref('safeFrames') / 60) * 1000;
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(note:Note, diff:Float = 0):Rating
	{
		var data:Array<Rating> = PlayState.ratingsData;
		for (i in 0...data.length - 1)
		{
			if (diff <= data[i].hitWindow)
				return data[i];
		} // skips last window (horse dog)
		return data[data.length - 1];
	}

	public static function getCrotchetAtTime(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.bpmChangeMap[i].stepTime <= step)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float
	{
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		return lastChange.songTime
			+ ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float)
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float)
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStepRounded(time) / 4);
	}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];
		var curBPM:Float = song.bpm;

		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			var note:SwagSection = song.notes[i];
			var noteBPM:Float = note.bpm;

			if (note.changeBPM && noteBPM != curBPM)
			{
				curBPM = noteBPM;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);

			totalSteps += deltaSteps;
			totalPos += (60 / curBPM) * 250 * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	inline public static function calculateCrochet(bpm:Float):Float { return (60 / bpm) * 1000; }
	static function getSectionBeats(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;

		if (song.notes[section] != null) val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}
	public static function changeBPM(newBpm:Float)
	{
		bpm = newBpm;

		crochet = calculateCrochet(bpm);
		stepCrochet = crochet / 4;
	}
}

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var counter:String = '';
	public var hitWindow:Null<Int> = 0; // ms
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;

	public function new(name:String)
	{
		this.image = name;
		this.name = name;

		this.hitWindow = ClientPrefs.getPref(name + 'Window', 0);
		this.counter = '${name}s';
	}
	public function increase(blah:Int = 1)
	{
		Reflect.setField(PlayState.instance, counter, Reflect.field(PlayState.instance, counter) + blah);
	}
}