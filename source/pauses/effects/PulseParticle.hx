package pauses.effects;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.effects.particles.FlxParticle;

class PulseParticle extends FlxParticle
{
	private var thisAlpha:Float;
	public function new()
	{
		super();
		exists = false;

		makeGraphic(10, 10, FlxColor.BLACK);
		thisAlpha = FlxG.random.float(.2, .4);
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var difference:Float = 1 - (age / lifespan);

		scale.set(difference, difference);
		alpha = difference * thisAlpha;
	}
}