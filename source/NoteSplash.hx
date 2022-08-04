package;

import shaders.ColorSwap;
import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;

	private var idleAnim:String;
	private var textureLoaded:String = null;

	private var library:String = null;
	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0, ?library:String = null)
	{
		super(x, y);
		this.library = library;

		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		loadAnims(skin);

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.getPref('globalAntialiasing');
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = 'noteSplashes', hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0)
	{
		setPosition(x - Note.swagWidth * .95, y - Note.swagWidth);
		alpha = .6;

		if (textureLoaded != texture) loadAnims(texture);
		colorSwap.hue = hueColor;

		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.finishCallback = function(name:String)
		{
			kill();
			animation.finishCallback = null;
		}
		animation.play('note$note-$animNum', true);
	}

	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin, library);
		for (i in 1...3)
		{
			animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
			animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
			animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
			animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}