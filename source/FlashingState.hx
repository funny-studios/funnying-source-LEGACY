package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var acceptImage:FlxGraphic = Paths.image('thumbsup');
	var backImage:FlxGraphic = Paths.image('disagree');

	var textY:Float = 0;

	var textSize:Int = 24;
	var delta:Float = 0;

	var warnText:FlxText;
	var bg:FlxSprite;

	override function create()
	{
		super.create();
		FlxG.sound.playMusic(Paths.music('warningTheme'), 1, true);

		var fill:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg = new FlxSprite().loadGraphic(Paths.image('stop'));

		bg.setGraphicSize(-1, Std.int(FlxG.height));
		bg.updateHitbox();

		bg.x = FlxG.width - bg.width;
		bg.screenCenter(Y);

		warnText = new FlxText(0, 0, FlxG.width * .8, "Hey, DUMBASS!\n
			This mod has flashing lights and motion that can LITERALLY kill you\nif you're epileptic.\n
			To ENABLE flashing lights, press ENTER.\nOtherwise, press ESCAPE or BACKSPACE to DISABLE them.\n
			Stay safe.", textSize);

		warnText.setFormat(Paths.font("comic.ttf"), textSize, FlxColor.GREEN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, true);
		warnText.bold = true;

		warnText.screenCenter(Y);
		warnText.x = textSize;

		textY = warnText.y;

		add(fill);
		add(bg);

		add(warnText);
	}

	override function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.initialZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1));
		if (!leftState)
		{
			delta = (delta + (elapsed * 3)) % (Math.PI * 2);

			var accept:Bool = controls.ACCEPT;
			var back:Bool = controls.BACK;

			if (back || accept)
			{
				leftState = true;

				FlxTransitionableState.skipNextTransOut = true;
				FlxTransitionableState.skipNextTransIn = true;

				ClientPrefs.prefs.set('reducedMotion', back);
				ClientPrefs.prefs.set('flashing', accept);

				ClientPrefs.saveSettings();
				FlxG.camera.zoom += .2;

				delta = 0;
				bg.loadGraphic(accept ? acceptImage : backImage);

				bg.setGraphicSize(-1, Std.int(FlxG.height));
				bg.updateHitbox();

				bg.x = FlxG.width - bg.width;
				bg.screenCenter(Y);

				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
				switch (accept)
				{
					default:
						{
							FlxG.sound.play(Paths.sound('cancelMenu'));
							FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
							{
								new FlxTimer().start(.5, function(tmr:FlxTimer)
								{
									MusicBeatState.switchState(new TitleState());
								});
							});
						}
					case true:
						{
							FlxG.sound.play(Paths.sound('confirmMenu'));
							FlxG.camera.flash(FlxColor.GREEN, 1);

							FlxFlicker.flicker(warnText, 1, .2, true, true, function(fkr:FlxFlicker)
							{
								FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
								{
									new FlxTimer().start(.5, function(tmr:FlxTimer)
									{
										MusicBeatState.switchState(new TitleState());
									});
								});
							});
						}
				}
			}
		}

		warnText.y = textY + (Math.sin(delta * 2) * 4);
		warnText.angle = Math.sin(delta);

		super.update(elapsed);
	}
}