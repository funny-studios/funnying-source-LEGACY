package;

import flixel.FlxSprite;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?antialiasing:Bool = true, ?animArray:Array<String> = null, ?loop:Bool = false)
	{
		super(x, y);
		switch (animArray != null)
		{
			case true:
			{
				frames = Paths.getSparrowAtlas(image);
				for (i in 0...animArray.length)
				{
					var anim:String = animArray[i];
					animation.addByPrefix(anim, anim, 24, loop);

					if (idleAnim == null)
					{
						idleAnim = anim;
						animation.play(anim);
					}
				}
			}
			default:
			{
				if (image != null) loadGraphic(Paths.image(image));
				active = false;
			}
		}

		scrollFactor.set(scrollX, scrollY);
		this.antialiasing = antialiasing && ClientPrefs.getPref('globalAntialiasing');
	}

	public function dance(?forceplay:Bool = false)
	{
		if (idleAnim != null)
			animation.play(idleAnim, forceplay);
	}
}