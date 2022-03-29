package;

import StageData.StageFile;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false) {
		super(x, y);

		var instance:PlayState = PlayState.instance;
		var stageData:StageFile = (instance != null && instance.exists && !(instance.isDead || instance.destroyed)) ? instance.stageData : null;

		var directory:Dynamic = stageData != null ? stageData.directory : null;
		var week:String = directory != null && directory.length > 0 ? directory : null;

		switch (animArray != null)
		{
			case true:
			{
				frames = Paths.getSparrowAtlas(image, week);
				for (i in 0...animArray.length) {
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
				if (image != null) loadGraphic(Paths.image(image, week));
				active = false;
			}
		}

		scrollFactor.set(scrollX, scrollY);
		antialiasing = ClientPrefs.globalAntialiasing;
	}
	public function dance(?forceplay:Bool = false) { if (idleAnim != null) animation.play(idleAnim, forceplay); }
}