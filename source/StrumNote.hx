package;

import flixel.animation.FlxAnimation;
import shaders.ColorSwap;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;


class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;

	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public var direction:Float = 90; // plan on doing scroll directions soon -bb
	public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	private var player:Int;

	public var texture(default, set):String = null;
	public var library:String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?library:String = null)
	{
		colorSwap = new ColorSwap();

		shader = colorSwap.shader;
		noteData = leData;

		this.player = player;
		this.library = library;
		this.noteData = leData;

		super(x, y);

		var skin:String = 'FUNNY_NOTE_assets';
		if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
			skin = PlayState.SONG.arrowSkin;

		texture = skin; // Load texture and anims
		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;

		if (animation.curAnim != null) lastAnim = animation.curAnim.name;
		frames = Paths.getSparrowAtlas(texture, library);

		animation.addByPrefix('green', 'arrowUP');
		animation.addByPrefix('blue', 'arrowDOWN');

		animation.addByPrefix('purple', 'arrowLEFT');
		animation.addByPrefix('red', 'arrowRIGHT');

		antialiasing = ClientPrefs.getPref('globalAntialiasing');
		setGraphicSize(Std.int(Note.swagWidth));
		//setGraphicSize(Std.int(width * Note.widthMul));

		var dir:String = switch(Math.abs(noteData) % 4)
		{
			case 3: 'right';
			case 1: 'down';
			case 2: 'up';

			default: 'left';
		}

		animation.addByPrefix('static', 'arrow${dir.toUpperCase()}', 24, false);

		animation.addByPrefix('confirm', '$dir confirm', 24, false);
		animation.addByPrefix('pressed', '$dir press', 24, false);

		updateHitbox();
		if (lastAnim != null) playAnim(lastAnim, true);
	}

	public function postAddedToGroup()
	{
		playAnim('static');

		x += Note.swagWidth * noteData;
		x += Note.swagWidth / 2;

		x += (FlxG.width / 2) * player;
		ID = noteData;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		var curAnim:FlxAnimation = animation.curAnim;
		if (curAnim != null && curAnim.name == 'confirm') centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);

		centerOffsets();
		centerOrigin();

		var curAnim:FlxAnimation = animation.curAnim;
		if (curAnim == null || curAnim.name == 'static')
		{
			colorSwap.hue = 0;

			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			// if (noteData >= 0 && noteData < ClientPrefs.arrowHSV.length)
			// {
			// 	colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
			// 	colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
			// 	colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
			// }
			if (curAnim != null && curAnim.name == 'confirm')
				centerOrigin();
		}
	}
}