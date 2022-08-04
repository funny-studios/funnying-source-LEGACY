#if web
import flixel.util.FlxColor;
import shaders.ColorSwap;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;

class AntiPiracyState extends FlxState
{
	private static var tau:Float = Math.PI * 2;
	private static var hueRepeat:Float = 360;

	var fuckYou:FlxSprite;
	var fuckText:FlxText;

	var shader:ColorSwap;
	var time:Float = 0;

	override public function create():Void
	{
		super.create();
		persistentUpdate = persistentDraw = true;

		FlxG.fixedTimestep = false;
		FlxG.mouse.visible = false;

		shader = new ColorSwap();
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height);

		fuckText = new FlxText(0, 0, FlxG.width, 'fuck you kbh and these dumbass fnf sites!!!!\nchoke, lick, and suck on my fat fucking cock!!!!!!!!!!!!!!', 16);
		fuckYou = new FlxSprite().loadGraphic(Paths.image('disagree'));

		fuckText.setFormat(Paths.font('comic.ttf'), fuckText.size, FlxColor.RED, CENTER);

		fuckText.borderColor = FlxColor.BLACK;
		fuckText.borderStyle = OUTLINE;
		fuckText.borderSize = 4;

		fuckYou.setGraphicSize(FlxG.width, Std.int(FlxG.height * .9));
		fuckYou.updateHitbox();

		fuckText.shader = shader.shader;
		fuckText.screenCenter();

		fuckYou.shader = shader.shader;
		fuckYou.screenCenter();

		fuckText.antialiasing = false;
		fuckYou.antialiasing = false;

		bg.antialiasing = false;
		add(bg);

		add(fuckYou);
		add(fuckText);

		FlxG.sound.playMusic(Paths.music('warningTheme'), 2);
		FlxG.sound.music.pan = -1;
	}
	override function update(elapsed:Float)
	{
		time += elapsed * 2;

		if (time >= tau) time %= tau;
		fuckYou.screenCenter();

		fuckYou.x += Math.sin(time * 10) * 30;
		fuckYou.y += Math.cos(time * 10) * 30;

		fuckText.angle = Math.sin(time) * 5;
		fuckYou.angle = fuckText.angle;

		shader.hue = time / tau;
	}
}
#end