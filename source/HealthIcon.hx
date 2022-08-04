package;

import flixel.animation.FlxAnimation;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public static var winningIconFrame:Int = 0;
	public static var neutralIconFrame:Int = 1;
	public static var losingIconFrame:Int = 2;

	public var sprTracker:FlxSprite;

	private var iconOffsets:Array<Float> = [0, 0];
	private var isPlayer:Bool = false;

	private var char:String = '';

	private var frameCount:Int = -1;
	private var thisFrame:Int = -1;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;

		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
	override function updateHitbox()
	{
		super.updateHitbox();

		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function setFrameOnPercentage(percent:Float)
	{
		var losingPercent:Float = PlayState.losingPercent;
		setFrame(switch (frameCount)
		{
			default: percent <= losingPercent ? losingIconFrame : (percent < (100 - losingPercent) ? neutralIconFrame : winningIconFrame);
			case 1 | 0: 0;
		});
	}
	public function setFrame(newFrame:Int)
	{
		var curAnim:FlxAnimation = animation.curAnim;

		if (curAnim != null) curAnim.curFrame = Std.int(CoolUtil.boundTo(newFrame - (3 - frameCount), 0, frameCount));
		thisFrame = newFrame;
	}

	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var file:Dynamic = Paths.image(getFirstExisting(['icons/$char', 'icons/icon-$char', 'icons/face', 'icons/icon-face']));
			loadGraphic(file); // Load stupidly first for getting the file size

			var cell:Int = Std.int(height);
			var newFrameCount:Int = Std.int(width / cell);

			if (thisFrame < 0) thisFrame = Std.int(Math.max(newFrameCount - 2, 0));
			frameCount = newFrameCount;

			var frameArray:Array<Int> = new Array<Int>();

			for (i in 0...frameCount) frameArray.push(i);
			loadGraphic(file, true, Std.int(width / frameCount), cell); // Then load it fr

			iconOffsets[0] = (width - cell) / frameCount;
			iconOffsets[1] = (width - cell) / frameCount;

			updateHitbox();

			animation.add(char, frameArray, 0, false, isPlayer);
			animation.play(char, true, false, thisFrame);

			this.char = char;

			setAntiAliasing();
			setFrame(thisFrame);
		}
	}

	public function getCharacter():String { return char; }
	private function getFirstExisting(names:Array<String>):String
	{
		for (i in 0...names.length)
		{
			var name:String = names[i];
			if (Paths.fileExists('images/$name.png', IMAGE))
			{
				trace('$name found at index $i');
				return name;
			}
		}
		return null;
	}
	private function setAntiAliasing()
	{
		var hasAA:Bool = switch (char)
		{
			case 'kong' | 'mbest' | 'bf-compressed' | 'gf-compressed': true;
			default: false;
		};
		antialiasing = hasAA && ClientPrefs.getPref('globalAntialiasing');
	}
}