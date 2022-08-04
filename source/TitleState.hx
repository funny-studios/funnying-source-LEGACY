package;

import flixel.FlxCamera;
import freeplay.FreeplayState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.app.Application;
import openfl.Assets;

using StringTools;
import Discord.DiscordClient;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var loopingDisableMechanics:Bool = false;
	public static var initialized:Bool = false;

	private static var titleJSON:TitleData;

	private static var tooMany:Int = 24;
	private var sickBeats:Int = -1; // Basically curBeat but won't be skipped if you hold the tab or resize the screen

	public static var closedState:Bool = false;
	private static var savesToLoad:Array<Array<Dynamic>> = [
		[ 'freeplayUnlocked', FreeplayState, 'unlocked' ],

		[ 'achievementsUnlocked', AchievementsState ],
		[ 'weekCompleted', StoryMenuState ]
	];

	var canYouFuckingWait:Bool = false;
	var skippedIntro:Bool = false;

	var dumbassLogo:FlxSprite;
	var typeTween:FlxTween;

	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;

	var curWacky:Array<String> = [];
	var logoScale:Float = .8;

	var camTransition:FlxCamera;
	var camOther:FlxCamera;
	var camGame:FlxCamera;

	var titleText:FlxSprite;
	var logoBl:FlxSprite;

	var transitioning:Bool = false;
	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;

		var path = Paths.getPreloadPath("images/titleJSON.json");
		titleJSON = Json.parse(Assets.getText(path));

		camTransition = new FlxCamera();
		camOther = new FlxCamera();
		camGame = new FlxCamera();

		camTransition.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camTransition, false);

		CustomFadeTransition.nextCamera = camTransition;

		FlxG.game.focusLostFramerate = 30;
		FlxG.sound.muteKeys = muteKeys;

		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;

		FlxG.keys.preventDefaultKeys = [ TAB ];
		PlayerSettings.init();

		curWacky = rollWacky();
		super.create();

		FlxG.save.bind('FUNNYING_DATA', BALLFART.saveName);

		ClientPrefs.loadPrefs();
		Highscore.load();

		var data:Dynamic = FlxG.save.data;
		if (data != null)
		{
			if (!initialized && data.fullscreen) FlxG.fullscreen = data.fullscreen;
			for (loading in savesToLoad)
			{
				var propertyName:String = loading[2];
				var dataName:String = loading[0];

				trace(dataName + ' - ' + propertyName);

				var value:Dynamic = Reflect.getProperty(data, dataName);
				if (value != null) Reflect.setProperty(loading[1], propertyName != null ? propertyName : dataName, value);
			}

			// if (FlxG.save.data.achievementsUnlocked != null) AchievementsState.achievementsUnlocked = FlxG.save.data.achievementsUnlocked;
			// if (FlxG.save.data.freeplayUnlocked != null) FreeplayState.unlocked = FlxG.save.data.freeplayUnlocked;
			// if (FlxG.save.data.weekCompleted != null) StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.fixedTimestep = false;
		FlxG.mouse.visible = false;

		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add(function(exitCode)
				{
					DiscordClient.shutdown();
				});
			}

			canYouFuckingWait = true;
			new FlxTimer().start(1, function(tmr:FlxTimer) { startIntro(); });
		}
	}

	public static function playTitleMusic(volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.music('funnyMenu'), volume);
		if (titleJSON != null)
			Conductor.changeBPM(titleJSON.bpm);
	}

	function startIntro()
	{
		persistentUpdate = true;

		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none") { bg.loadGraphic(Paths.image(titleJSON.backgroundSprite)); }
		else { bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK); }

		bg.antialiasing = globalAntialiasing;
		bg.screenCenter();

		add(bg);

		logoBl = new FlxSprite();
		logoBl.frames = Paths.getSparrowAtlas('Start_Screen_Assets');

		logoBl.antialiasing = globalAntialiasing;

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');

		logoBl.setGraphicSize(Std.int(logoBl.width * logoScale));

		logoBl.updateHitbox();
		logoBl.screenCenter();

		logoBl.x += titleJSON.titlex;
		logoBl.y += titleJSON.titley;

		titleText = new FlxSprite().loadGraphic(Paths.image('enter'));
		titleText.antialiasing = globalAntialiasing;

		titleText.setGraphicSize(Std.int(titleText.width * .8));

		titleText.updateHitbox();
		titleText.screenCenter();

		titleText.x += titleJSON.startx;
		titleText.y += titleJSON.starty;

		dumbassLogo = new FlxSprite().loadGraphic(Paths.image('gobbledegook'));

		dumbassLogo.setGraphicSize(Std.int(dumbassLogo.width * 1.2));
		dumbassLogo.updateHitbox();

		dumbassLogo.screenCenter(X);
		dumbassLogo.y = FlxG.height - dumbassLogo.height - 40;

		dumbassLogo.visible = false;

		credGroup = new FlxGroup();
		textGroup = new FlxGroup();

		add(logoBl);
		add(titleText);
		add(credGroup);

		credGroup.add(bg);
		credGroup.add(dumbassLogo);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;
		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 3, {ease: FlxEase.quadInOut, type: PINGPONG});

		switch (initialized)
		{
			case true: skipIntro();
			default:
			{
				initialized = true;
				playTitleMusic(0);

				FlxG.sound.music.fadeIn(4, 0, .7);
				FlxG.sound.music.play(true);

				Conductor.songPosition = 0;
				beatHit();
			}
		}
		canYouFuckingWait = false;
	}
	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
			swagGoodArray.push(i.split('--'));
		return swagGoodArray;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time + elapsed;
		// sometimes it jsut dont go....
		FlxG.mouse.visible = false;
		super.update(elapsed);

		if (canYouFuckingWait) return;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				pressedEnter = true;
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		var sinkInput:Bool = false;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START #if switch || gamepad.justPressed.B #end)
				pressedEnter = true;
		}
		if (!transitioning && skippedIntro)
		{
			if (!sinkInput)
			{
				if (FlxG.keys.justPressed.D) CoolUtil.browserLoad('https://www.youtube.com/watch?v=hUTu2_0ElK8');
				if (FlxG.keys.justPressed.F) FlxG.fullscreen = !FlxG.fullscreen;
				#if debug
				if (FlxG.keys.justPressed.R)
				{
					transitioning = true;
					loopingDisableMechanics = true;

					LoadingState.loadAndSwitchState(new DisableMechanicsState(), false, true);
				}
				#end
			}
			if (pressedEnter && !sinkInput)
			{
				transitioning = true;
				switch (ClientPrefs.getPref('flashing'))
				{
					case true:
					{
						FlxG.camera.flash(FlxColor.WHITE, 1, null, true);
						FlxFlicker.flicker(titleText);
					}
					default:
					{
						FlxG.camera.fade(FlxColor.BLACK, 1, false, null, true);
						FlxTween.tween(titleText, {alpha: 0}, 1);
					}
				}
				FlxG.sound.play(Paths.sound('confirmMenu'), .7);
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();
		if (ClientPrefs.getPref('camZooms'))
		{
			var lerpSpeed:Float = CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1);
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.initialZoom, FlxG.camera.zoom, lerpSpeed);
		}
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var text:String = textArray[i];
			var textSize:Float = CoolUtil.boundTo(tooMany / text.length, .5, 1);

			var money:Alphabet = new Alphabet(0, 0, text, true, false, 0, textSize);

			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;

			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var textSize:Float = CoolUtil.boundTo(tooMany / text.length, .5, 1);
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false, 0, textSize);

			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;

			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function canZoomCamera():Bool
	{
		return skippedIntro && ClientPrefs.getPref('camZooms');
	}

	function rollWacky(?comparing:Array<String> = null):Array<String>
	{
		return FlxG.random.getObject(getIntroTextShit());
	}

	function deleteCoolText()
	{
		while (textGroup.length > 0)
		{
			var member = textGroup.members[0];
			if (member != null)
			{
				credGroup.remove(member, true);
				textGroup.remove(member, true);

				member.destroy();
			}
			else
			{
				break;
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (logoBl != null) logoBl.animation.play('bump', true);

		if (canZoomCamera()) FlxG.camera.zoom += .045;
		if (!closedState)
		{
			// sickBeats++;
			for (i in sickBeats...curBeat)
			{
				switch (i + 1)
				{
					case 0:
						createCoolText(['Pandemonium', 'Top 10 Awesome'], -40);
					case 4:
						addMoreText('and other idiots', -40);
					case 6:
						addMoreText('present', -40);

					case 8:
						deleteCoolText();

					case 12:
						createCoolText(['a mod for', 'the friday night funkin'], -40);
					case 14:
					{
						if (dumbassLogo != null) dumbassLogo.visible = true;
						addMoreText('wait... what mod is this?', -40);
					}

					case 16:
					{
						if (dumbassLogo != null)
						{
							dumbassLogo.visible = false;
							dumbassLogo.kill();

							credGroup.remove(dumbassLogo);

							dumbassLogo.destroy();
							dumbassLogo = null;
						}
						deleteCoolText();
					}

					case 20:
						createCoolText([curWacky[0]]);
					case 22:
						addMoreText(curWacky[1]);

					case 24:
						deleteCoolText();

					case 28:
						createCoolText(['friday night funnying']);
					case 30:
						addMoreText('vs funny bf');

					case 32:
						skipIntro();
				}
			}
			sickBeats = curBeat;
		}
	}
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(credGroup);

			camGame.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}