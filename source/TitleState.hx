package;

import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
#if (desktop && !neko)
import Discord.DiscordClient;
#end
#if desktop
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;
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

	public static var initialized:Bool = false;
	private static var titleJSON:TitleData;

	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;

	var curWacky:Array<String> = [];
	var logoScale:Float = .8;

	var titleText:FlxSprite;
	var logoBl:FlxSprite;

	var transitioning:Bool = false;
	public static var updateVersion:String = '';
	override public function create():Void
	{
		var path = Paths.getPreloadPath("images/titleJSON.json");
		titleJSON = Json.parse(Assets.getText(path));

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;

		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;

		FlxG.keys.preventDefaultKeys = [ TAB ];
		PlayerSettings.init();

		curWacky = rollWacky();
		super.create();

		FlxG.save.bind('funnying', 'funnyboyfriend');

		ClientPrefs.loadPrefs();
		Highscore.load();

		if (FlxG.save.data.weekCompleted != null) StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			MusicBeatState.switchState(new FlashingState());
		} else {
			#if (desktop && !neko)
			DiscordClient.initialize();
			Application.current.onExit.add (function (exitCode) {
				DiscordClient.shutdown();
			});
			#end
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end
	}
	public static function playTitleMusic(volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.music('funnyMenu'), volume);
		if (titleJSON != null) Conductor.changeBPM(titleJSON.bpm);
	}
	function startIntro()
	{
		if (!initialized)
		{
			playTitleMusic(0);

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			FlxG.sound.music.play(true);
		}

		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none") { bg.loadGraphic(Paths.image(titleJSON.backgroundSprite)); }
		else { bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK); }

		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.screenCenter();

		add(bg);

		logoBl = new FlxSprite();
		logoBl.frames = Paths.getSparrowAtlas('Start_Screen_Assets');

		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');

		logoBl.setGraphicSize(Std.int(logoBl.width * logoScale));

		logoBl.updateHitbox();
		logoBl.screenCenter();

		logoBl.x += titleJSON.titlex;
		logoBl.y += titleJSON.titley;

		titleText = new FlxSprite().loadGraphic(Paths.image('enter'));
		titleText.antialiasing = ClientPrefs.globalAntialiasing;

		titleText.setGraphicSize(Std.int(titleText.width * .8));

		titleText.updateHitbox();
		titleText.screenCenter();

		titleText.x += titleJSON.startx;
		titleText.y += titleJSON.starty;

		credGroup = new FlxGroup();
		textGroup = new FlxGroup();

		add(logoBl);
		add(titleText);
		add(credGroup);

		credGroup.add(bg);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;
		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, { ease: FlxEase.quadInOut, type: PINGPONG });

		switch (initialized)
		{
			default: initialized = true;
			case true: skipIntro();
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray) swagGoodArray.push(i.split('--'));
		return swagGoodArray;
	}
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time + elapsed;
		if (FlxG.keys.justPressed.F) FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		#if mobile
		for (touch in FlxG.touches.list) { if (touch.justPressed) pressedEnter = true; }
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) { if (gamepad.justPressed.START #if switch || gamepad.justPressed.B #end ) pressedEnter = true; }
		if (!transitioning && skippedIntro)
		{
			if (pressedEnter)
			{
				switch (ClientPrefs.flashing)
				{
					case true:
					{
						FlxG.camera.flash(FlxColor.WHITE, 1, null, true);
						FlxFlicker.flicker(titleText);
					}
					default:
					{
						FlxG.camera.fade(FlxColor.BLACK, 1, false, null, true);
						FlxTween.tween(titleText, { alpha: 0 }, 1);
					}
				}

				FlxG.sound.play(Paths.sound('confirmMenu'), .7);
				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (pressedEnter && !skippedIntro) skipIntro();
		if (ClientPrefs.camZooms)
		{
			var lerpSpeed:Float = CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1);
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.initialZoom, FlxG.camera.zoom, lerpSpeed);
		}
		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);

			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;

			if (credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function canZoomCamera():Bool { return skippedIntro && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms; }

	function rollWacky(?comparing:Array<String> = null):Array<String> { return FlxG.random.getObject(getIntroTextShit()); }
	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = -1; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (logoBl != null) logoBl.animation.play('bump', true);
		if (canZoomCamera())
		{
			var beatMod = sickBeats % 2;
			FlxG.camera.zoom += .045 / (beatMod == 1 ? 2 : 1);
		}
		if (!closedState) {
			// sickBeats++;
			for (i in sickBeats...curBeat)
			{
				switch (i + 1)
				{
					case 0: createCoolText(['Daniyar Gaming', 'Top 10 Awesome'], -40);
					case 4: addMoreText('and other idiots', -40);
					case 6: addMoreText('present', -40);

					case 8: deleteCoolText();

					case 12: createCoolText(['In association', 'with'], -40);
					case 14: addMoreText('ewrdgfvbnehjrduwgivudewsrigjuvseijvgbijrweihjgkrdkb', -40);

					case 16: deleteCoolText();

					case 20: createCoolText([curWacky[0]]);
					case 22: addMoreText(curWacky[1]);

					case 24: deleteCoolText();

					case 28: addMoreText('friday night funnying');
					case 30: addMoreText('vs funny bf');

					case 32: skipIntro();
				}
			}
			sickBeats = curBeat;
		}
	}

	var skippedIntro:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}