import Alphabet.AlphaCharacter;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

using StringTools;

class ResetScoreSubState extends MusicBeatSubstate
{
	private static var downscaleLength:Int = 18;

	var bg:FlxSprite;

	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;

	var onYes:Bool = false;

	var yesText:Alphabet;
	var noText:Alphabet;

	var song:String;

	var difficulty:Int;
	var week:Int;
	// Week -1 = Freeplay
	public function new(song:String, difficulty:Int, character:String, week:Int = -1)
	{
		this.song = song;

		this.difficulty = difficulty;
		this.week = week;

		super();
		var name:String = song;

		if (week >= 0) name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName.toLowerCase();
		name += ' on ${CoolUtil.difficulties[difficulty]}';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height);
		bg.alpha = 0;

		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = CoolUtil.boundTo(downscaleLength / name.length, .4, 1);
		var text:Alphabet = new Alphabet(0, 180, "do yoy wanna reset", true);

		text.screenCenter(X);

		alphabetArray.push(text);
		text.alpha = 0;

		add(text);

		var text:Alphabet = new Alphabet(0, text.y + 90, name, true, false, 0, tooLong);
		text.screenCenter(X);

		alphabetArray.push(text);
		text.alpha = 0;

		add(text);
		if (week < 0)
		{
			icon = new HealthIcon(character);

			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();

			icon.setPosition(text.x - (icon.width / tooLong), text.y - (30 / tooLong));
			icon.alpha = 0;

			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);

		yesText.x -= 200;
		add(yesText);

		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);

		noText.x += 200;

		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		bg.alpha = Math.min(bg.alpha + (elapsed * 3), .3);

		var deltaTime:Float = elapsed * 2.5;
		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			spr.alpha += deltaTime;
		}

		if (week < 0) icon.alpha += deltaTime;
		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;

			updateOptions();
		}
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		}
		else
		{
			if (controls.ACCEPT)
			{
				if (onYes)
				{
					if (week < 0) { Highscore.resetSong(song, difficulty); }
					else { Highscore.resetWeek(WeekData.weeksList[week], difficulty); }
				}

				FlxG.sound.play(Paths.sound(onYes ? 'cuh' : 'cancelMenu'), 1);
				close();
			}
		}
		super.update(elapsed);
	}

	function updateOptions()
	{
		var alphas:Array<Float> = [.6, 1.25];
		var scales:Array<Float> = [.75, 1];

		var confirmInt:Int = CoolUtil.boolToInt(onYes);

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);

		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);

		if (week < 0) icon.setFrame(confirmInt * 2); // icon.animation.curAnim.curFrame = confirmInt;
		bg.color = switch (ClientPrefs.getPref('flashing'))
		{
			case true: onYes ? FlxColor.GREEN : FlxColor.RED;
			default: FlxColor.BLACK;
		};
	}
}