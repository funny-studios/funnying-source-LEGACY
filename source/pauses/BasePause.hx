package pauses;

import flixel.group.FlxGroup;

class BasePause extends FlxGroup
{
	private var instance:PauseSubState;
	// just recreate musicbeatstate lol
	private var crochet:Float;
	private var stepCrochet:Float;

	private var lastBeat:Int;
	private var lastStep:Int;

	private var curBeat:Int;
	private var curStep:Int;

	private var bpm:Float = -1;
	private var loop:Bool;

	public function new(instance:PauseSubState, ?bpm:Float, loop:Bool = false)
	{
		super();
		this.instance = instance;

		if (bpm != null)
		{
			this.loop = loop;
			this.bpm = bpm;

			crochet = (60 / bpm) * 1000;
			stepCrochet = crochet / 4;

			lastBeat = -1;
			lastStep = -1;

			curBeat = 0;
			curStep = 0;
		}
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (bpm > 0)
		{
			var songPosition:Float = instance.pauseMusic.time + elapsed;

			curStep = Math.floor((songPosition - ClientPrefs.getPref('noteOffset')) / stepCrochet);
			curBeat = Math.floor(curStep / 4);

			if (curStep > lastStep) stepHit();
			lastStep = curStep;
		}
	}

	public function beatHit() {}
	public function stepHit()
	{
		if (lastStep >= curStep) return;
		if ((curStep % 4) == 0)
		{
			if (loop && curBeat > lastBeat)
			{
				var tempBeat:Int = curBeat;
				for (i in lastBeat + 1...tempBeat)
				{
					curBeat = i;
					beatHit();
				}
				curBeat = tempBeat;
			}
			beatHit();
		}
		lastBeat = curBeat;
	}
}