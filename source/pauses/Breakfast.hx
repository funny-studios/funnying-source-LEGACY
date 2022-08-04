package pauses;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;

class Breakfast extends Default
{
	private var breakfast:FlxSprite;
	private var time:Float = 0;

	public function new(instance:PauseSubState)
	{
		super(instance);
		breakfast = new FlxSprite().loadGraphic(Paths.image('pausemenu/breakfast'));

		breakfast.setGraphicSize(Std.int(breakfast.width * .25));
		breakfast.updateHitbox();

		breakfast.screenCenter(Y);
		breakfast.x = FlxG.width + (breakfast.width * 2);

		breakfast.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		breakfast.scrollFactor.set();

		add(breakfast);
		FlxTween.tween(breakfast, { x: FlxG.width - (breakfast.width * 1.5) }, 1, { ease: FlxEase.quartOut, startDelay: .4 });
	}
	override function update(elapsed:Float)
	{
		time = (time + (elapsed * 2)) % (Math.PI * 2);
		breakfast.angle = Math.sin(time) * 10;
	}
	override function destroy()
	{
		remove(breakfast);

		breakfast.destroy();
		super.destroy();
	}
}