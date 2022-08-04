package pauses;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Default extends BasePause
{
	public function new(instance:PauseSubState, ?bpm:Float, loop:Bool = false)
	{
		super(instance, bpm, loop);
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		bg.scrollFactor.set();
		bg.alpha = 0;

		add(bg);
		FlxTween.tween(bg, { alpha: .6 }, .4, { ease: FlxEase.quartOut });
	}
}