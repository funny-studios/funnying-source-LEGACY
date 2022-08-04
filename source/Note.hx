package;

import flixel.animation.FlxAnimation;
import editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;

using StringTools;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;

	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	public var gfNote:Bool = false;

	public var animSuffix:String = '';

	public var earlyHitMult:Float = .5;
	public var lateHitMult:Float = 1;

	public var lowPriority:Bool = false;
	public static var widthMul:Float = .7;

	public static var noteWidth:Int = 160;
	public static var swagWidth:Float = noteWidth * widthMul;

	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = .023;
	public var missHealth:Float = .0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, .25 = shit, .5 = bad, .75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var library:String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String
	{
		noteSplashTexture = PlayState.SONG.splashSkin;
		// if (noteData >= 0 && noteData < ClientPrefs.arrowHSV.length)
		// {
		// 	colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
		// 	colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
		// 	colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
		// }
		if (noteData >= 0 && noteType != value)
		{
			if (!isSustainNote) earlyHitMult = 1;
			switch (value)
			{
				case 'Alt Animation': animSuffix = '-alt';
				case 'horse cheese note':
				{
					ignoreNote = true;
					lowPriority = true;

					texture = "horse_cheese_notes";

					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;

					noteSplashDisabled = true;
					lateHitMult = 1;

					earlyHitMult = .3;
					lateHitMult = .4;

					hitCausesMiss = !isSustainNote;
				}

				case 'No Animation':
				{
					noAnimation = true;
					noMissAnimation = true;
				}
			}
			noteType = value;
		}

		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?library:String = null)
	{
		super();
		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.library = library;

		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.getPref('middleScroll') ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + (swagWidth / 2);
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= FlxG.height * 2;

		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.getPref('noteOffset');

		this.noteData = noteData;
		if (noteData > -1)
		{
			texture = '';

			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * noteData;
			if (!isSustainNote && noteData >= 0 && noteData < 4)
			{
				var animToPlay:String = switch (noteData % 4)
				{
					case 0: 'purple';
					case 1: 'blue';
					case 2: 'green';
					case 3: 'red';

					default: '';
				}
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);
		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			hitsoundDisabled = true;

			multAlpha = .6;
			alpha = multAlpha;

			if (ClientPrefs.getPref('downScroll'))
				flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(switch (noteData % 4)
			{
				default: 'purpleholdend';

				case 2: 'greenholdend';
				case 1: 'blueholdend';
				case 3: 'redholdend';
			});

			updateHitbox();
			offsetX -= width / 2;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData % 4)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;

				if (PlayState.instance != null)
					prevNote.scale.y *= PlayState.instance.songSpeed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
		x += offsetX;
	}

	public function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '')
	{
		if (prefix == null)
			prefix = '';
		if (texture == null)
			texture = '';
		if (suffix == null)
			suffix = '';

		var skin:String = texture;
		if (skin.length < 1)
		{
			skin = PlayState.SONG.arrowSkin;
			if (skin == null || skin.length < 1) skin = 'FUNNY_NOTE_assets';
		}

		var curAnim:FlxAnimation = animation.curAnim;
		var animName:String = curAnim != null ? curAnim.name : null;

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		frames = Paths.getSparrowAtlas(blahblah, library);
		switch (skin)
		{
			case 'FUNNY_NOTE_assets': setGraphicSize(noteWidth);
		}
		loadNoteAnims();

		antialiasing = ClientPrefs.getPref('globalAntialiasing');
		if (isSustainNote)
			scale.y = lastScaleY;

		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
		if (inEditor)
		{
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}
	function loadNoteAnims()
	{
		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('purpleScroll', 'purple0');

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
		}

		//setGraphicSize(Std.int(width * widthMul));
		setGraphicSize(Std.int(width * widthMul));
		updateHitbox();
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var songPosition:Float = Conductor.songPosition;
		var earlyZone:Float = songPosition + (Conductor.safeZone * earlyHitMult);

		if (mustPress)
		{
			var lateZone:Float = songPosition - (Conductor.safeZone * lateHitMult);
			// ok river
			canBeHit = strumTime >= lateZone && strumTime <= earlyZone;
			if (strumTime < (songPosition - Conductor.safeZone) && !wasGoodHit) tooLate = true;
		}
		else
		{
			canBeHit = false;
			if (strumTime <= earlyZone)
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
		if (tooLate && !inEditor)
			alpha = Math.min(alpha, .3);
	}
}