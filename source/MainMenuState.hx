package;

import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import freeplay.FreeplayState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;

using StringTools;

import Discord.DiscordClient;
#if debug
import editors.MasterEditorMenu;
#end

class MainMenuState extends MusicBeatState
{
	public static var quandaleEngineVersion:String = '1.0.0';
	public static var physicsEngineVersion:String = '0.6.2';

	private static var menuPath:String = 'menucustom/';
	private static var libraryPath:String = Paths.getLibraryPath('images/$menuPath');

	private static var assetList:Array<String>;

	private static var backgroundPath:String = 'backgrounds/';
	private static var iconPath:String = 'icons/';

	private static var backgroundList:Array<String>;
	private static var iconList:Array<String>;

	public static var curSelected:Int = 0;

	private var camGame:FlxCamera;
	private var camFriday:FlxCamera;
	private var camOther:FlxCamera;

	var optionShit:Array<String> = ['story_mode', 'freeplay', 'achievements', 'credits', 'options'];
	var menuItems:FlxTypedGroup<FlxSprite>;

	var iconPadding:Float = 100;
	var iconSize:Int = 200;

	var pickOffset:Float = 100;
	var offsetY:Float = 140;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var fridayScale:Float = .5;
	var fridayDelta:Float = 0;

	var friday:FlxSprite;
	var icon:FlxSprite;

	var selectedSomethin:Bool = false;
	private var lastBeatHit:Int = -1;
	override function create()
	{
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		camGame = new FlxCamera();

		camFriday = new FlxCamera();
		camOther = new FlxCamera();

		camFriday.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camFriday, false);
		FlxG.cameras.add(camOther, false);

		CustomFadeTransition.nextCamera = camOther;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		if (assetList == null) assetList = Assets.list(IMAGE);
		if (backgroundList == null)
		{
			backgroundList = new Array<String>();
			filter(backgroundList, libraryPath + backgroundPath);
		}
		if (iconList == null)
		{
			iconList = new Array<String>();
			filter(iconList, libraryPath + iconPath);
		}

		var backgroundRoll:Int = FlxG.random.int(0, backgroundList.length) - 1;
		var iconRoll:Int = FlxG.random.int(0, iconList.length - 1);

		var selectedBackground:String = backgroundList[backgroundRoll];
		var selectedIcon:String = iconList[iconRoll];

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image(selectedBackground != null ? (menuPath + selectedBackground) : 'menuBG'));

		var customCredits:String = (selectedBackground != null ? 'background by ${getHandle(selectedBackground)}\n' : '') + 'icon by ${getHandle(selectedIcon)}\n\n';
		var yScroll:Float = 1 / (optionShit.length * 2);

		var globalAntialiasing = ClientPrefs.getPref('globalAntialiasing');
		icon = new FlxSprite().loadGraphic(Paths.image(menuPath + selectedIcon));

		icon.scrollFactor.set(0, yScroll / 2);
		icon.setGraphicSize(iconSize, iconSize);

		icon.updateHitbox();
		icon.screenCenter(Y);

		icon.y += iconPadding;
		icon.x = iconPadding;

		icon.antialiasing = globalAntialiasing;
		icon.cameras = [camGame];

		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));

		bg.updateHitbox();
		bg.screenCenter();

		bg.antialiasing = globalAntialiasing;
		bg.cameras = [camGame];

		magenta = new FlxSprite(-80).loadGraphic(Paths.image(selectedBackground != null ? (menuPath + selectedBackground) : 'menuBGMagenta'));
		if (selectedBackground != null) magenta.color = 0xFFFD71F4;

		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));

		magenta.updateHitbox();
		magenta.screenCenter();

		magenta.visible = false;
		magenta.antialiasing = globalAntialiasing;

		magenta.cameras = [camGame];

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		camFollow.cameras = [camGame];
		camFollowPos.cameras = [camGame];

		add(bg);
		add(magenta);

		add(icon);

		add(camFollow);
		add(camFollowPos);

		var curDate = Date.now();
		var hours:Int = curDate.getHours();

		if (#if debug friday == null #else (curDate.getDay() == 5 && hours >= 20) || (curDate.getDay() == 6 && hours <= 5) #end)
		{
			trace('It\'s Friday Night!! $hours');

			friday = new FlxSprite().loadGraphic(Paths.image('frid'));
			friday.scrollFactor.set();

			friday.setGraphicSize(Std.int(friday.width * fridayScale));
			friday.updateHitbox();

			friday.alpha = .9;

			friday.x = 50;
			friday.y = 50;

			friday.cameras = [camFriday];
			add(friday);
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		menuItems.cameras = [camGame];

		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, i * offsetY).loadGraphic(Paths.image('mainmenu/menu_${optionShit[i]}'));
			menuItem.ID = i;

			menuItem.antialiasing = globalAntialiasing;
			menuItem.scrollFactor.set(0, 1);

			menuItem.updateHitbox();
			menuItem.x = FlxG.width + (menuItem.width * 2) + pickOffset;

			menuItem.cameras = [camGame];
			menuItems.add(menuItem);

			FlxTween.tween(menuItem, {x: FlxG.width - menuItem.width - 10}, .5, {startDelay: .5 + (i / 10), ease: FlxEase.backOut});
		}
		camGame.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(0, 0, FlxG.width, '${customCredits}Quandale Dingle Engine v$quandaleEngineVersion (physics engine $physicsEngineVersion)\nfunny friday v${Application.current.meta.get('version')}', 12);
		versionShit.scrollFactor.set();

		versionShit.setFormat(Paths.font("comic.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.updateHitbox();

		versionShit.x = 8;
		versionShit.y = FlxG.height - (versionShit.height + versionShit.x);

		versionShit.cameras = [camGame];

		add(versionShit);
		changeItem();

		camFollowPos.y = camFollow.y;
		super.create();
	}

	function getHandle(str:String):String { return '@' + str.split('/').pop(); }
	function filter(array:Array<Dynamic>, start:String)
	{
		for (asset in assetList)
		{
			if (asset.startsWith(start))
			{
				var split:Array<String> = asset.split('/');
				var ext:Array<String> = split.pop().split('.');

				ext.pop();
				array.push(split.pop() + '/' + ext.join('.'));
			}
		}
	}
	function doShit(daChoice:String)
	{
		CustomFadeTransition.nextCamera = camOther;
		var newState:Dynamic = switch (daChoice)
		{
			case 'options': options.OptionsState;

			case 'achievements': AchievementsState;
			case 'story_mode': StoryMenuState;
			case 'freeplay': FreeplayState;
			case 'credits': CreditsState;

			default: null;
		}
		if (newState != null) MusicBeatState.switchState(Type.createInstance(newState, []));
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (.5 * elapsed), .8);
			Conductor.songPosition = FlxG.sound.music.time + elapsed;
		}
		if (friday != null)
		{
			fridayDelta += elapsed * 4;
			friday.scale.set(fridayScale + (Math.sin(fridayDelta) * (fridayScale / 2)), fridayScale + (Math.cos(fridayDelta) * (fridayScale / 2)));
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

				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				var daChoice:String = optionShit[curSelected];
				switch (daChoice)
				{
					default:
						{
							var flashing:Bool = ClientPrefs.getPref('flashing');
							if (flashing)
								FlxFlicker.flicker(magenta, 1.1, .15, false, true);
							menuItems.forEach(function(spr:FlxSprite)
							{
								if (curSelected == spr.ID)
								{
									switch (flashing)
									{
										case true:
											FlxFlicker.flicker(spr, 1, .06, false, true, function(flick:FlxFlicker)
											{
												doShit(daChoice);
												// flick.destroy();
											});
										default:
											FlxTween.tween(spr, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
											{
												doShit(daChoice);
												twn.destroy();
											}});
									}
								}
								else
								{
									FlxTween.tween(spr, {alpha: 0}, .4, {
										ease: FlxEase.quadOut,
										onComplete: function(twn:FlxTween)
										{
											spr.kill();
											twn.destroy();
										}
									});
								}
							});
						}
				}
			}
			#if debug
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;

				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		if (ClientPrefs.getPref('camZooms')) camGame.zoom = FlxMath.lerp(camGame.initialZoom, camGame.zoom, CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1));

		menuItems.forEach(function(spr:FlxSprite) { spr.offset.x = FlxMath.lerp(spr.offset.x, (spr.ID == curSelected) ? (pickOffset + (spr.width / 2)) : 0, lerpVal); });
		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();
		if (ClientPrefs.getPref('camZooms') && lastBeatHit < curBeat) camGame.zoom += .03;
		lastBeatHit = curBeat;
	}

	function changeItem(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, menuItems.length);
		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == curSelected)
				camFollow.setPosition(0, spr.getGraphicMidpoint().y);
		});
	}
}