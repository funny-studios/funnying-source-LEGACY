package;

import flixel.util.FlxTimer;
import flixel.input.actions.FlxAction;
import flixel.math.FlxRandom;
#if (desktop && !neko)
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.1'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options',
		'comic'
	];

	var pickOffset:Float = 100;
	var offsetY:Float = 140;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	private var lastBeatHit:Int = -1;
	override function create()
	{
		#if (desktop && !neko)
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(.25 - (.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));

		var offset:Float = 108 - ((Math.max(optionShit.length, 4) - 4) * 80);

		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));

		bg.updateHitbox();
		bg.screenCenter();

		bg.antialiasing = ClientPrefs.globalAntialiasing;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		add(bg);

		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuBGMagenta'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;

		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, (i * offsetY) + offset).loadGraphic(Paths.image('mainmenu/menu_${optionShit[i]}'));

			menuItem.scale.set(scale, scale);
			menuItem.ID = i;

			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.scrollFactor.set(0, 1);

			menuItem.updateHitbox();
			menuItem.x = FlxG.width + (menuItem.width * 2) + pickOffset;

			menuItems.add(menuItem);
			FlxTween.tween(menuItem, { x: FlxG.width - menuItem.width - 10 }, .5, { startDelay: .5 + (i / 10), ease: FlxEase.backOut });
		}

		FlxG.camera.follow(camFollowPos, null, 1);
		var versionShit:FlxText = new FlxText(8, FlxG.height - 48, 0, 'Psych Engine v$psychEngineVersion', 12);

		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font("comic.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		add(versionShit);
		var versionShit:FlxText = new FlxText(8, FlxG.height - 28, 0, 'funny friday v${Application.current.meta.get('version')}', 12);

		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font("comic.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		add(versionShit);
		changeItem();

		camFollowPos.y = camFollow.y;
		super.create();
	}

	var selectedSomethin:Bool = false;
	function doShit(daChoice:String)
	{
		switch (daChoice)
		{
			case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay': MusicBeatState.switchState(new FreeplayState());
			case 'credits': MusicBeatState.switchState(new CreditsState());
			case 'options': MusicBeatState.switchState(new options.OptionsState());
		}
	}
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (.5 * elapsed), .8);
			Conductor.songPosition = FlxG.sound.music.time + elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(0, FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			var delta:Int = CoolUtil.getDelta(controls.UI_DOWN_P, controls.UI_UP_P);
			if (delta != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(delta);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;

				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				var daChoice:String = optionShit[curSelected];
				switch (daChoice)
				{
					case 'comic':
					{
						menuItems.forEach(function(spr:FlxSprite)
						{
							if (curSelected == spr.ID)
							{
								var flashLen:Float = .5;
								if (ClientPrefs.flashing)
								{
									FlxFlicker.flicker(magenta, flashLen + .2, .15, false, true);
									FlxFlicker.flicker(spr, flashLen, .06, true, false);
								}
								new FlxTimer().start(flashLen, function(tmr:FlxTimer) {
									CoolUtil.browserLoad('https://daniyargaming.carrd.co/#');

									selectedSomethin = false;
									tmr.destroy();
								});
								return;
							}
						});
					}
					default:
					{
						if (ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, .15, false, true);
						menuItems.forEach(function(spr:FlxSprite)
						{
							if (curSelected == spr.ID)
							{
								switch (ClientPrefs.flashing)
								{
									case true: FlxFlicker.flicker(spr, 1, .06, false, true, function(flick:FlxFlicker) { doShit(daChoice); });
									default: FlxTween.tween(spr, { alpha: 0 }, 1, { onComplete: function(twn:FlxTween) { doShit(daChoice); } });
								}
							} else {
								FlxTween.tween(spr, { alpha: 0 }, .4, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});
							}
						});
					}
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		if (ClientPrefs.camZooms) camGame.zoom = FlxMath.lerp(FlxG.camera.initialZoom, camGame.zoom, CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1));

		menuItems.forEach(function(spr:FlxSprite) { spr.offset.x = FlxMath.lerp(spr.offset.x, (spr.ID == curSelected) ? (pickOffset + (spr.width / 2)) : 0, lerpVal); });
		super.update(elapsed);
	}
	override function beatHit()
	{
		super.beatHit();
		if (canZoomCamera() && lastBeatHit != curBeat)
		{
			var beatMod = curBeat % 2;

			camGame.zoom += .03 / (beatMod == 1 ? 2 : 1);
			lastBeatHit = curBeat;
		}
	}

	function canZoomCamera():Bool { return camGame.zoom < 1.35 && ClientPrefs.camZooms; }
	function changeItem(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, menuItems.length);
		menuItems.forEach(function(spr:FlxSprite) { if (spr.ID == curSelected) camFollow.setPosition(0, spr.getGraphicMidpoint().y); });
	}
}