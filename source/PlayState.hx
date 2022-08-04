package;

import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import lime.ui.Window;
import lime.app.Application;
import AchievementsState.Achievement;
import openfl.media.Sound;
import freeplay.FreeplayState;
import shaders.Shaders.GlitchEffect;
import flixel.system.FlxAssets.FlxShader;
import shaders.ColorSwap;
import shaders.WiggleEffect;
import openfl.display.Skip;
import haxe.io.Bytes;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import Controls.Control;
import DialogueBox;
import Note.EventNote;
import Section.SwagSection;
import Song.SwagSong;
import StageData;
import Conductor.Rating;
import editors.CharacterEditorState;
import editors.ChartingState;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;
import Discord.DiscordClient;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['horse dog phase 2', .2], // From 0% to 19%
		['horse dog', .4], // From 20% to 39%
		['kill yourself', .5], // From 40% to 49%
		['am busy', .6], // From 50% to 59%
		['fuck yo u', .7], // From 60% to 69%
		['Goog', .8], // From 70% to 79%
		['grangt', .9], // From 80% to 89%
		['Funny!', 1], // From 90% to 99%
		['standing ovation', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];
	public static var introAssets:Map<String, Array<String>> = [
		'compressed' => ['ready', 'set', 'go'],
		'default' => ['rady', 'set', 'kys']
	];
	// event variables
	public var modchartTweens:Array<FlxTween> = new Array<FlxTween>();
	public var modchartTimers:Array<FlxTimer> = new Array<FlxTimer>();

	private var isCameraOnForcedPos:Bool = false;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = Note.noteWidth * 2;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;

	public static var storyMisses:Map<String, Int> = [];
	public static var storyPlaylist:Array<String>;

	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;
	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;

	public var worldStrumLineNotes:FlxTypedGroup<StrumNote>;
	public var worldNotes:FlxTypedGroup<Note>;

	private var worldStrumLine:FlxSprite;

	public var secondOpponentStrums:FlxTypedGroup<StrumNote>;
	public var stageGroup:FlxTypedGroup<BGSprite>;

	public var duoOpponent:Character;
	public var pinkSoldier:Character;

	public var bgDancers:BGSprite;
	public var fgDancers:BGSprite;
	public var funnyGF:BGSprite;

	private static var introAssetsLibrary:String = null;

	private static var otherAssetsLibrary:String = null;
	private static var noteAssetsLibrary:String = null;

	private static var introAssetsSuffix:String = '';

	private var healthDrainCap:Float = 1 / 2;
	private var healthDrain:Float = 1 / 45;

	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;

	public var health:Float = 1;
	public var maxHealth:Float = 2;

	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;

	public var timeBar:FlxBar;

	public static var ratingsData:Array<Rating> = [];

	public var funnies:Int = 0;
	public var googs:Int = 0;
	public var bads:Int = 0;
	public var horsedogs:Int = 0;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var camZoomTypeBeatOffset:Int = 0;
	public var camZoomType:Int = 0;
	public var camZoomTypes:Array<Array<Dynamic>>;

	var dialogueJson:DialogueFile = null;

	var cameraOffset:Float = 25;
	var secondOpponentDelta:FlxPoint;

	var opponentDelta:FlxPoint;
	var playerDelta:FlxPoint;

	var bananaStrumsHidden:Bool = false;

	public var DUO_X:Float = -325;
	public var DUO_Y:Float = 125;

	public static var introKey:String;

	public static var losingPercent:Float = 20;
	private var vocalResyncTime:Int = 20;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public static var mechanicsEnabled:Bool = ClientPrefs.getPref('mechanics');
	public var defaultCamZoom:Float = 1.05;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	public var totalShitsFailed:Int = 0;
	public var shitsFailedLol:Int = 0;

	public var isDead:Bool = false;

	var gameZoomAdd:Float = 0;
	var hudZoomAdd:Float = 0;

	var gameZoom:Float = 1;
	var hudZoom:Float = 1;

	var circleTime:Float = 0;
	// [ divide by, minimum difficulty ]
	var healthDrainMap:Map<String, Dynamic> = [
		'kleptomaniac' => [4, 0],
		'roided' => [2, 0]
	];

	var shaders:Array<Dynamic>;
	var skipCutscene:Skip;
	#if VIDEOS_ALLOWED
	var video:MP4Handler;
	#end

	var hitsoundsPlayed:Array<Int>;	// no......no......no......no.......
	var timerExtensions:Array<Float>;

	var vignetteEnabled:Bool = false;
	var vignetteImage:FlxSprite;

	var subtitlesTxt:FlxText;

	var gameShakeAmount:Float = 0;
	var hudShakeAmount:Float = 0;

	var maskedSongLength:Float = -1;
	var songLength:Float = 0;

	var horseImages:Array<FlxGraphic>;
	var shitFlipped:Bool = false;

	private static var introSoundPrefix:String = '';

	static var ease:Dynamic = FlxEase.cubeInOut;
	static var startDelay:Float = 0;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public var paused:Bool = false;
	public var canReset:Bool = true;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var storyDifficultyText:String = "";
	// Discord RPC variables
	var detailsText:String = "";
	var detailsPausedText:String = "";

	var authorGroup:FlxSpriteGroup;

	public static var instance:PlayState;
	public static var focused:Bool = true;

	public var stageData:StageFile;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	public var strumsBlocked:Array<Bool> = [];
	override public function create()
	{
		Paths.clearStoredMemory();
		instance = this;

		opponentDelta = new FlxPoint();
		playerDelta = new FlxPoint();

		shaders = new Array<FlxShader>();

		camZoomType = 0;
		// [ On Beat (bool), Function ]
		camZoomTypes = [
			[
				true,
				function()
				{
					if ((curBeat + camZoomTypeBeatOffset) % 4 == 0)
					{
						gameZoomAdd += .015;
						hudZoomAdd += .03;
					}
				}
			],
			[
				true,
				function()
				{
					if ((curBeat + camZoomTypeBeatOffset) % 2 == 0)
					{
						gameZoomAdd += .015;
						hudZoomAdd += .03;
					}
				}
			],
			[
				true,
				function()
				{
					gameZoomAdd += .015;
					hudZoomAdd += .03;
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 32)
					{
						case 0 | 3 | 6 | 10 | 14 | 28: 1;

						case 16 | 17 | 18 | 19 | 22 | 23 | 24 | 25 | 30: 4;
						case 7 | 11 | 31: -3;

						default: false;
					};
					if (beatDiv != false)
					{
						gameZoomAdd += .015 / beatDiv;
						hudZoomAdd += .03 / beatDiv;
					}
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 16)
					{
						case 0 | 2 | 4 | 6 | 8 | 10 | 12: 1;

						case 1 | 3 | 5 | 7 | 9 | 11: -Math.PI / 2;
						case 13 | 14 | 15: -3;

						default: false;
					};
					if (beatDiv != false)
					{
						gameZoomAdd += .015 / beatDiv;
						hudZoomAdd += .03 / beatDiv;
					}
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 32)
					{
						case 0 | 3 | 4 | 7 | 8 | 11 | 12 | 15 | 16 | 18 | 20 | 22 | 23 | 24 | 27 | 28 | 30 | 31: 2;
						default: false;
					};
					if (beatDiv != false)
					{
						gameZoomAdd += .015 / beatDiv;
						hudZoomAdd += .03 / beatDiv;
					}
				}
			],
			[
				false,
				function()
				{
					var beatDiv:Dynamic = switch ((curStep + (camZoomTypeBeatOffset * 4)) % 64)
					{
						case 16 | 22 | 48 | 52 | 56 | 60: 1;
						case 0 | 32: .7;

						default: false;
					}
					if (beatDiv != false)
					{
						gameZoomAdd += .015 / beatDiv;
						hudZoomAdd += .03 / beatDiv;
					}
				}
			]
		];

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		PauseSubState.songName = null; // Reset to default
		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];
		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		// Gameplay settings
		healthGain = #if !debug isStoryMode ? 1 : #end ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = #if !debug  isStoryMode ? 1 : #end ClientPrefs.getGameplaySetting('healthloss', 1);

		instakillOnMiss = #if !debug !isStoryMode && #end ClientPrefs.getGameplaySetting('instakill', false);
		cpuControlled = #if !debug !isStoryMode && #end ClientPrefs.getGameplaySetting('botplay', false);

		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		var lowQuality:Bool = ClientPrefs.getPref('lowQuality');
		var hideHUD:Bool = ClientPrefs.getPref('hideHud');

		var healthBarAlpha:Float = ClientPrefs.getPref('healthBarAlpha');
		var timeBarType:String = ClientPrefs.getPref('timeBarType');

		var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
		var downScroll:Bool = ClientPrefs.getPref('downScroll');

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();

		camHUD = new FlxCamera();
		camOther = new FlxCamera();

		camOther.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>(12);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null) SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? 'Story Mode: ${WeekData.getCurrentWeek().weekName}' : "Freeplay";
		// String for when the game is paused
		detailsPausedText = 'Paused - $detailsText';

		curSong = Paths.formatToSongPath(SONG.song);
		curStage = StageData.getStage(SONG);

		cacheShitForSong(SONG);
		var windowText:String = '?';

		var application:Application = Application.current;
		var applicationWindow:Window = null;

		if (application != null)
		{
			applicationWindow = application.window;

			var meta:Map<String, String> = application.meta;
			if (meta != null && meta.exists('name')) windowText = meta.get('name');
		}

		var authorPath:String = 'data/$curSong/author.txt';
		var absoluteAuthorPath:String = Paths.getPath(authorPath, TEXT);

		if (Paths.fileExists(authorPath, TEXT))
		{
			trace('path fooound');

			var authorList:String = CoolUtil.coolTextFile(absoluteAuthorPath).join('\n');
			authorGroup = new FlxSpriteGroup();

			var authors:String = '$authorList - ${SONG.song}';
			var boxWidth:Int = Std.int(FlxG.width * .4);

			var authorPadding:Float = 8;
			var authorHeight:Int = 50;

			var iconSize:Int = Std.int((authorHeight - authorPadding) * .9);
			var authorText:FlxText = new FlxText(0, 0, boxWidth - iconSize - (authorPadding * 2), authors);

			authorText.setFormat(Paths.font('comic.ttf'), 24, FlxColor.WHITE, LEFT);
			authorText.updateHitbox();

			var authorBG:FlxSprite = new FlxSprite().makeGraphic(boxWidth, authorHeight + Std.int(authorText.height - authorText.size), FlxColor.BLACK);
			var authorIcon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('song'));

			authorText.x = iconSize + (authorPadding * 2);

			authorIcon.setGraphicSize(iconSize, iconSize);
			authorIcon.updateHitbox();

			authorText.y = (authorBG.height - authorText.height) / 2;

			authorIcon.y = (authorBG.height - iconSize) / 2;
			authorIcon.x = authorPadding;

			authorIcon.antialiasing = globalAntialiasing;
			authorText.antialiasing = globalAntialiasing;

			authorBG.antialiasing = false;

			authorIcon.alpha = .75;
			authorText.alpha = authorIcon.alpha;

			authorBG.alpha = .5;

			authorText.cameras = [ camOther ];
			authorBG.cameras = [ camOther ];

			authorGroup.cameras = [ camOther ];

			authorGroup.x = FlxG.width - authorBG.width;
			authorGroup.screenCenter(Y);

			authorGroup.y += authorBG.height;
			authorGroup.add(authorBG);

			authorGroup.add(authorIcon);
			authorGroup.add(authorText);

			windowText += ' - $authorList';
		}
		if (applicationWindow != null) applicationWindow.title = windowText + ' - ${SONG.song} [ $storyDifficultyText ]';

		stageData = StageData.getStageFile(curStage);
		startDelay = Conductor.crochet / 1000;

		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: .9,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],

				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		gameZoom = defaultCamZoom;

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];

		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];

		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		opponentCameraOffset = stageData.camera_opponent;
		girlfriendCameraOffset = stageData.camera_girlfriend;

		if (boyfriendCameraOffset == null)
			boyfriendCameraOffset = [0, 0]; // Fucks sake should have done it since the start :rolling_eyes:
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		stageGroup = new FlxTypedGroup<BGSprite>();
		switch (curStage)
		{
			case 'stage' | 'stage-compressed': // Tutorial
			{
				var bg:BGSprite = new BGSprite('stageback', -600, -200);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);

				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();

				add(stageFront);
				if (!lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, .9, .9);

					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();

					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, .9, .9);

					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();

					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);

					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * .9));
					stageCurtains.updateHitbox();

					add(stageCurtains);
				}
			}

			case 'grass': // Funny BF
			{
				var bushes:BGSprite = new BGSprite('grass/bushes', -500, -100, .8, .9);

				var bg:BGSprite = new BGSprite('grass/bg', -600, -100, .2, .2);
				var fg:BGSprite = new BGSprite('grass/fg', -500, -100);

				add(bg);
				add(bushes);
				add(fg);
			}
			case 'hell': // Evil BF
			{
				var bg:BGSprite = new BGSprite('hell', -600, -300, 1, 1, false);

				bg.setGraphicSize(Std.int(bg.width * 1.25));
				bg.updateHitbox();

				add(bg);
			}
			case 'youtooz': // YouTooz BF
			{
				var bg:BGSprite = new BGSprite('youtooz', -800, -550);

				bg.setGraphicSize(Std.int(bg.width * 3));
				bg.updateHitbox();

				add(bg);
				if (!lowQuality)
				{
					duoOpponent = new Character(0, 0, SONG.player2.endsWith('youtooz') ? 'funnybf' : 'funnybf-youtooz');
					funnyGF = new BGSprite('background/gametoons-gf', 250, 300, 1, 1, ['idle']);

					stageGroup.add(funnyGF);
					switch (curSong)
					{
						case 'funny-duo':
						{
							fgDancers = new BGSprite('background/funnyduofgcharacters', -250, 400, .5, .25, ['foreground characters']);
							bgDancers = new BGSprite('background/funnyduobgcharacters', 0, 125, 1, 1, ['background characters']);

							bgDancers.setGraphicSize(Std.int(bgDancers.width * .8));
							fgDancers.setGraphicSize(Std.int(fgDancers.width * .8));

							fgDancers.updateHitbox();
							bgDancers.updateHitbox();

							stageGroup.add(fgDancers);
							stageGroup.add(bgDancers);
						}
					}
				}
			}

			case 'relapse': // Relapse BF
			{
				var bg:BGSprite = new BGSprite('analprolapse');

				bg.setGraphicSize(Std.int(bg.width * 1.5));
				bg.updateHitbox();

				add(bg);
			}
			case 'minion': // Banana
			{
				var bg:BGSprite = new BGSprite('stage', -350, -300);

				bg.setGraphicSize(Std.int(bg.width * 1.15));
				bg.updateHitbox();

				add(bg);
			}
			case 'mspaint': // Braindead
			{
				var bg:BGSprite = new BGSprite('mspaint', -600, 100);

				bg.setGraphicSize(Std.int(bg.width * 1.5));
				bg.updateHitbox();

				add(bg);
			}
			case 'kong': // the kong
			{
				var bg:BGSprite = new BGSprite('back');

				bg.setGraphicSize(Std.int(bg.width * 4));
				bg.updateHitbox();

				add(bg);
			}
			case 'squidgame': // Squid Games
			{
				var bg:BGSprite = new BGSprite('back', -420, -220);

				pinkSoldier = new Character(120, 0, "pinksoldier");
				dadGroup.add(pinkSoldier);

				bg.setGraphicSize(Std.int(bg.width * 1.5));
				bg.updateHitbox();

				add(bg);
			}
			case 'screwed': // also in the name dumbass... tird of the dang and bambi
			{
				var bg:BGSprite = new BGSprite('corn', -620, 0);

				bg.setGraphicSize(Std.int(bg.width * 3));
				bg.updateHitbox();

				add(bg);
			}
		}
		switch (curStage)
		{
			case 'squidgame':
			{
				secondOpponentStrums = new FlxTypedGroup<StrumNote>();
				secondOpponentDelta = new FlxPoint();
			}
		}

		if (bgDancers != null) add(bgDancers);
		if (funnyGF != null) add(funnyGF);

		add(gfGroup);

		add(dadGroup);
		add(boyfriendGroup);

		var gfVersion:String = switch (curStage)
		{
			case 'tutorial': 'gf-compressed';
			default: 'gf';
		};
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);

			gf.scrollFactor.set(.95, .95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);

		if (pinkSoldier != null) startCharacterPos(pinkSoldier);

		dadGroup.add(dad);
		if (duoOpponent != null)
		{
			dadGroup.add(duoOpponent);
			duoOpponent.setPosition(DAD_X + DUO_X, DAD_Y + DUO_Y);

			startCharacterPos(duoOpponent);
		}

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		if (fgDancers != null) add(fgDancers);
		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		var camPos:FlxPoint = new FlxPoint();
		if (gf != null)
		{
			camPos.set(girlfriendCameraOffset[0]
				+ gf.getMidpoint().x
				+ gf.cameraPosition[0],
				girlfriendCameraOffset[1]
				+ gf.getMidpoint().y
				+ gf.cameraPosition[1]);
		}
		else
		{
			camPos.set(opponentCameraOffset[0]
				+ dad.getMidpoint().x
				+ 150
				+ dad.cameraPosition[0],
				opponentCameraOffset[1]
				+ dad.getMidpoint().y
				- 100
				+ dad.cameraPosition[1]);
		}

		var file:String = Paths.json('$curSong/dialogue'); // Checks for json/Physics Engine dialogue
		if (OpenFlAssets.exists(file))
			dialogueJson = DialogueBox.parseDialogue(file);

		Conductor.songPosition = -5000;
		strumLine = new FlxSprite(middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);

		if (downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var widthAdd:Float = 1.05;
		var underlayWidth:Float = Note.swagWidth * widthAdd;

		var spriteUnderlayWidth:Int = Std.int(underlayWidth * 4);
		var underlayHeight:Int = FlxG.height * 2;

		var scrollUnderlay:FlxSprite = new FlxSprite().makeGraphic(spriteUnderlayWidth, underlayHeight, FlxColor.BLACK);
		var halfWidth:Float = FlxG.width / 2;

		scrollUnderlay.alpha = ClientPrefs.getPref('scrollUnderlay');
		scrollUnderlay.scrollFactor.set();

		scrollUnderlay.cameras = [ camHUD ];
		switch (middleScroll)
		{
			case true: scrollUnderlay.screenCenter(X);
			default:
			{
				var dumbFuckingMathBullshit:Float = STRUM_X + ((underlayWidth * widthAdd) / Note.widthMul / 2) / 2;
				scrollUnderlay.setPosition(dumbFuckingMathBullshit + halfWidth);

				if (ClientPrefs.getPref('opponentStrums'))
				{
					var opponentUnderlay:FlxSprite = new FlxSprite(dumbFuckingMathBullshit).makeGraphic(spriteUnderlayWidth, underlayHeight, FlxColor.BLACK);

					opponentUnderlay.scrollFactor.set(scrollUnderlay.scrollFactor.x, scrollUnderlay.scrollFactor.y);
					opponentUnderlay.alpha = scrollUnderlay.alpha;

					opponentUnderlay.cameras = scrollUnderlay.cameras;
					add(opponentUnderlay);
				}
			}
		}

		add(scrollUnderlay);
		var showTime:Bool = timeBarType != 'Disabled';

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 0, 400, "", 32);
		timeTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		timeTxt.antialiasing = globalAntialiasing;

		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;

		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;

		if (downScroll)
			timeTxt.y = FlxG.height - 44;
		if (timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		updateTime = showTime;
		timeBarBG = new AttachedSprite('timeBar');

		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4) + 4;

		timeBarBG.antialiasing = globalAntialiasing;

		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;

		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;

		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;

		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();

		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 200; // How much lag this causes?? Should i tone it down to idk, 400 or 200?

		timeBar.alpha = 0;
		timeBar.visible = showTime;

		timeBar.antialiasing = globalAntialiasing;

		add(timeBar);
		add(timeTxt);

		timeBarBG.sprTracker = timeBar;
		// yes...
		if (ClientPrefs.getPref('subtitles'))
		{
			subtitlesTxt = new FlxText(0, 0, FlxG.width, "", 32);
			subtitlesTxt.setFormat(Paths.font("comic.ttf"), subtitlesTxt.size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

			subtitlesTxt.bold = true;
			subtitlesTxt.scrollFactor.set();

			subtitlesTxt.borderSize = 2;
			subtitlesTxt.alpha = .8;

			subtitlesTxt.antialiasing = globalAntialiasing;
			subtitlesTxt.cameras = [camOther];
		}
		if (secondOpponentStrums != null)
		{
			if (pinkSoldier != null)
			{
				worldStrumLine = new FlxSprite(pinkSoldier.x - 50, pinkSoldier.y - 100).makeGraphic(FlxG.width, 10);
				worldStrumLine.scrollFactor.set(1, 1);
			}

			worldStrumLineNotes = new FlxTypedGroup<StrumNote>();
			add(worldStrumLineNotes);
		}

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if (timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0, noteAssetsLibrary);

		grpNoteSplashes.add(splash);
		splash.alpha = 0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		noteTypeMap.clear();
		noteTypeMap = null;

		eventPushedMap.clear();
		eventPushedMap = null;

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		camGame.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.focusOn(camFollow);
		gameZoomAdd = 0;

		camGame.zoom = gameZoom + gameZoomAdd;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		isCameraOnForcedPos = true;
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');

		healthBarBG.y = FlxG.height * .89;
		healthBarBG.screenCenter(X);

		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !hideHUD;

		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;

		add(healthBarBG);
		if (downScroll) healthBarBG.y = .11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, shitFlipped ? LEFT_TO_RIGHT : RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'health', 0, 2);
		healthBar.scrollFactor.set();

		healthBar.numDivisions = 400;
		// healthBar
		healthBar.visible = !hideHUD;
		healthBar.alpha = healthBarAlpha;

		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		var p2:Character = shitFlipped ? boyfriend : dad;
		var p1:Character = shitFlipped ? dad : boyfriend;

		iconP1 = new HealthIcon(p1.healthIcon, true);

		iconP1.visible = !hideHUD;
		iconP1.alpha = healthBarAlpha;

		add(iconP1);
		iconP2 = new HealthIcon(p2.healthIcon, false);

		iconP1.y = healthBar.y - 75;
		iconP2.y = iconP1.y;

		iconP2.visible = !hideHUD;
		iconP2.alpha = healthBarAlpha;

		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "");

		scoreTxt.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.borderSize = 1.25;

		scoreTxt.scrollFactor.set();

		scoreTxt.visible = !hideHUD;
		scoreTxt.antialiasing = globalAntialiasing;

		add(scoreTxt);
		botplayTxt = new FlxText(0, timeBarBG.y + 30, FlxG.width - 800, "this person\nis cheating", 32);

		botplayTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();

		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;

		botplayTxt.antialiasing = globalAntialiasing;

		botplayTxt.updateHitbox();
		botplayTxt.screenCenter(X);

		add(botplayTxt);

		if (authorGroup != null) add(authorGroup);
		if (downScroll)
			botplayTxt.y = timeBarBG.y - 118;
		if (worldStrumLineNotes != null)
			worldStrumLineNotes.cameras = [camGame];

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		notes.cameras = [camHUD];

		GameOverSubstate.resetVariables();
		switch (curStage)
		{
			case 'stage-compressed':
			{
				GameOverSubstate.deathSoundLibrary = 'compressed';
				GameOverSubstate.loopSoundLibrary = 'compressed';
				GameOverSubstate.endSoundLibrary = 'compressed';

				GameOverSubstate.endSoundName = 'gameOverEnd';
				GameOverSubstate.loopSoundName = 'gameOver';

				GameOverSubstate.conductorBPM = 100;
			}
		}

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = .7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		if (isStoryMode && !seenCutscene)
		{
			switch (curSong)
			{
				case 'gastric-bypass':
					startVideo('animation_gastric_bypass');
				case 'roided':
					startVideo('animation_roided');

				case 'kleptomaniac':
					startVideo('animation_evil_bf');

				case 'cervix':
					startVideo('animation_cervix');
				case 'funny-duo':
					startVideo('animation_funny_duo');
				case 'intestinal-failure':
					startVideo('animation_intestinal_failure');

				default: startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating(true); // no-zoom

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter());
		if (!ClientPrefs.getPref('controllerMode'))
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.create();
		Paths.clearUnusedMemory();
		// CustomFadeTransition.nextCamera = camOther;
	}

	public static function cacheShitForSong(SONG:SwagSong)
	{
		var songName:String = Paths.formatToSongPath(SONG.song);
		// Ratings
		ratingsData = new Array<Rating>();

		var rating:Rating = new Rating('funny');
		rating.hitWindow = ClientPrefs.getPref('funnyWindow');

		rating.counter = 'funnies';
		ratingsData.push(rating); //default rating

		var rating:Rating = new Rating('goog');
		rating.hitWindow = ClientPrefs.getPref('googWindow');

		rating.noteSplash = false;
		rating.counter = 'googs';

		rating.ratingMod = .7;
		rating.score = 200;

		ratingsData.push(rating);
		var rating:Rating = new Rating('bad');
		rating.hitWindow = ClientPrefs.getPref('badWindow');

		rating.noteSplash = false;
		rating.counter = 'bads';

		rating.ratingMod = .4;
		rating.score = 100;

		ratingsData.push(rating);
		var rating:Rating = new Rating('horsedog');

		rating.counter = 'horsedogs';
		rating.noteSplash = false;

		rating.ratingMod = 0;
		rating.score = 50;

		ratingsData.push(rating);

		introAssetsLibrary = null;
		otherAssetsLibrary = null;
		noteAssetsLibrary = null;

		introAssetsSuffix = '';
		introKey = switch (songName)
		{
			case 'tutorial':
			{
				introAssetsLibrary = 'compressed';

				otherAssetsLibrary = introAssetsLibrary;
				noteAssetsLibrary = introAssetsLibrary;

				'compressed';
			}
			default: 'default';
		};

		Paths.image('combo', otherAssetsLibrary);
		Paths.image(getNoteSplash());

		for (i in 0...10) Paths.image('num$i', otherAssetsLibrary);
		for (rating in ratingsData) Paths.image(rating.image, otherAssetsLibrary);
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		Hitsound.play(true);
		for (i in 0...3) CoolUtil.precacheSound('missnote${i + 1}');

		if (PauseSubState.songName != null) { CoolUtil.precacheMusic(PauseSubState.songName); }
		else
		{
			var pauseMusic:String = ClientPrefs.getPref('pauseMusic');
			if (pauseMusic != null && pauseMusic != 'None') { CoolUtil.precacheMusic(Paths.formatToSongPath(pauseMusic)); }
		}
	}
	public function getFormattedSong(?getRating:Bool = true)
	{
		var start = '${SONG.song} ($storyDifficultyText)';
		if (getRating)
		{
			var floored:String = ratingName == '?' ? '?' : '$ratingName (${Highscore.floorDecimal(ratingPercent * 100, 2)}%)';
			start += '\nscore: $songScore | horse cheeses: $songMisses | rating: $floored';
		}
		return start;
	}

	private function quickUpdatePresence(?startString:String = "", ?hasLength:Bool = true)
	{
		if (health > 0 && !paused && DiscordClient.isInitialized)
			DiscordClient.changePresence(detailsText, '$startString${getFormattedSong()}', iconP2.getCharacter(), hasLength && Conductor.songPosition > 0,
				songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh

			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}

		songSpeed = value;
		noteKillOffset = (Note.noteWidth * 2) / songSpeed;

		return value;
	}

	function cancelCameraDelta(char:Character, forceDad:Bool = false)
	{
		if (!char.animation.name.startsWith('sing'))
		{
			var deltaCancel:FlxPoint = switch (char.isPlayer)
			{
				default: (char != dad && !forceDad) ? secondOpponentDelta : opponentDelta;
				case true: playerDelta;
			};
			deltaCancel.set();
		}
	}

	function getCameraDelta(leData:Int):FlxPoint
	{
		return new FlxPoint(switch (leData)
		{
			case 0: -1;
			case 3: 1;

			default: 0;
		}, switch (leData)
			{
				case 2: -1;
				case 1: 1;

				default: 0;
			});
	}

	public function reloadHealthBarColors()
	{
		var p1Colors:Array<Int> = boyfriend.healthColorArray;
		var p2Colors:Array<Int> = dad.healthColorArray;

		healthBar.createFilledBar(FlxColor.fromRGB(p2Colors[0], p2Colors[1], p2Colors[2]), FlxColor.fromRGB(p1Colors[0], p1Colors[1], p1Colors[2]));
		healthBar.updateBar();
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);

			char.scrollFactor.set(.95, .95);
			char.danceEveryNumBeats = 2;
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function startVideo(name:String, skipTransIn:Bool = false)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		if(!#if sys FileSystem #else OpenFlAssets #end.exists(filepath))
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd(skipTransIn);
			return;
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		bg.cameras = [ camOther ];
		bg.scrollFactor.set();

		video = new MP4Handler();
		video.finishCallback = function()
		{
			if (bg != null)
			{
				bg.kill();
				remove(bg);

				bg.destroy();
				bg = null;
			}
			if (skipCutscene != null)
			{
				FlxG.removeChild(skipCutscene);
				skipCutscene = null;
			}
			startAndEnd(skipTransIn);
			return;
		}

		var skipPadding:Float = 10;
		var skipSize:Int = 32;

		skipCutscene = new Skip(skipPadding, FlxG.height - skipPadding, skipSize, .8, 0xFFFF0000);
		skipCutscene.y -= skipCutscene.height;

		add(bg);

		skipCutscene.visible = true;
		video.playVideo(filepath, false, false);

		FlxG.addChildBelowMouse(skipCutscene);
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd(skipTransIn);

		return;
		#end
	}

	function startAndEnd(skipTransIn:Bool = false)
	{
		switch (endingSong)
		{
			case true:
				cleanupEndSong(skipTransIn);
			default:
				startCountdown();
		}
		// if (endingSong)
		//	endSong();
		// else
		//	startCountdown();
	}

	var dialogueCount:Int = 0;

	public var physicsDialogue:DialogueBox;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (physicsDialogue != null)
			return;
		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;

			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');

			physicsDialogue = new DialogueBox(dialogueFile, song);
			physicsDialogue.scrollFactor.set();

			physicsDialogue.finishThing = function()
			{
				switch (endingSong)
				{
					default:
						startCountdown();
					case true:
						endSong();
				}
			}

			physicsDialogue.nextDialogueThing = startNextDialogue;
			physicsDialogue.cameras = [camHUD];

			add(physicsDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			switch (endingSong)
			{
				default:
					startCountdown();
				case true:
					endSong();
			}
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer;

	public var countdownImage:FlxSprite;

	public static var startOnTime:Float = 0;

	private function charDance(char:Character, beat:Int)
	{
		var curAnim:FlxAnimation = char.animation.curAnim;
		if (curAnim != null && (beat % (gfGroup.members.contains(char) ? (char.danceEveryNumBeats * gfSpeed) : char.danceEveryNumBeats)) == 0)
		{
			if (!char.stunned && (curAnim.finished || !curAnim.name.startsWith("sing"))) char.dance();
		}
	}

	private function stageDance(beat:Int) { if (beat % gfSpeed == 0) { for (sprite in stageGroup.members) { if (Std.isOfType(sprite, BGSprite)) cast(sprite, BGSprite).dance(true); } } }
	private function groupDance(chars:FlxSpriteGroup, beat:Int) { for (char in chars.members) { if (Std.isOfType(char, Character)) charDance(cast(char, Character), beat); } }

	private function bfDance()
	{
		var curAnim:FlxAnimation = boyfriend.animation.curAnim;
		if (curAnim != null)
		{
			var animName = curAnim.name;
			if (boyfriend.holdTimer > ((Conductor.stepCrochet / 1000) * boyfriend.singDuration)
				&& (animName.startsWith("sing") && !animName.endsWith("miss")))
				boyfriend.dance();
		}
	}
	public function startCountdown():Void
	{
		inCutscene = false;
		isCameraOnForcedPos = false;

		skipCountdown = false;
		if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		if (secondOpponentStrums != null) generateStaticArrows(2);
		startedCountdown = true;

		var introAlts:Array<String> = introAssets.get(introKey);
		var lastTween:FlxTween = null;

		Conductor.songPosition = -startDelay * 5000;
		if (startOnTime > 0)
		{
			if (FlxG.sound.music != null) { FlxG.sound.music.volume = 0; }

			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);

			return;
		}
		else if (skipCountdown)
		{
			setSongTime(0);
			return;
		}
		countdownImage = new FlxSprite();

		countdownImage.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		countdownImage.scrollFactor.set();

		countdownImage.cameras = [camHUD];
		countdownImage.alpha = 0;

		insert(members.indexOf(notes), countdownImage);
		// So it doesn't lag
		for (alt in introAlts) Paths.image(alt, introAssetsLibrary);
		for (i in 1...4) { CoolUtil.precacheSound('${introSoundPrefix}intro$i$introAssetsSuffix', introAssetsLibrary); }

		CoolUtil.precacheSound('${introSoundPrefix}introGo$introAssetsSuffix', introAssetsLibrary);
		startTimer = new FlxTimer().start(startDelay, function(tmr:FlxTimer)
		{
			if (ClientPrefs.getPref('opponentStrums'))
			{
				notes.forEachAlive(function(note:Note)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;

					if (ClientPrefs.getPref('middleScroll') && !note.mustPress)
						note.alpha *= .5;
				});
			}

			var loopsLeft:Int = tmr.loopsLeft;
			var beat:Int = loopsLeft + 1;

			var count = tmr.elapsedLoops - 2;

			groupDance(gfGroup, beat);
			groupDance(boyfriendGroup, beat);
			groupDance(dadGroup, beat);

			stageDance(beat);
			iconBop(beat);

			if ((count >= 0 && count < introAlts.length) && countdownImage != null)
			{
				countdownImage.loadGraphic(Paths.image(introAlts[count], introAssetsLibrary));
				// FUCK HAXEFLIXEL
				if (lastTween != null && !lastTween.finished)
				{
					lastTween.cancel();
					cleanupTween(lastTween);
					lastTween = null;
				}

				countdownImage.updateHitbox();
				countdownImage.screenCenter();

				countdownImage.alpha = 1;
				var tween:FlxTween = FlxTween.tween(countdownImage, {alpha: 0}, Conductor.crochet / 1000, {
					ease: ease,
					onComplete: function(twn:FlxTween)
					{
						if (loopsLeft <= 0)
						{
							countdownImage.alpha = 0;
							remove(countdownImage);
							countdownImage.destroy();
						}
						lastTween = null;
						cleanupTween(twn);
					}
				});

				modchartTweens.push(tween);
				lastTween = tween;
			}

			var introSound:FlxSound = new FlxSound().loadEmbedded(Paths.sound('${introSoundPrefix}intro${loopsLeft <= 0 ? 'Go' : Std.string(loopsLeft)}$introAssetsSuffix', introAssetsLibrary), false, true);
			introSound.volume = .6;

			FlxG.sound.list.add(introSound);
			introSound.play(true);
		}, 4);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if (time >= 0 && time < FlxG.sound.music.length)
		{
			FlxG.sound.music.play(true);
			FlxG.sound.music.time = time;
		}
		if (SONG.needsVoices && vocals != null && time >= 0 && time < vocals.length)
		{
			vocals.play(true);
			vocals.time = time;
		}

		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue()
	{
		dialogueCount++;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(SONG.song), 0, false);
		FlxG.sound.music.onComplete = finishSong.bind();

		FlxG.sound.music.play(true);
		if (vocals != null)
		{
			vocals.volume = 0;
			if (SONG.needsVoices) vocals.play(true);
		}

		Conductor.songPosition = FlxG.sound.music.time;
		resyncVocals(true, true);
		// Conductor.songPosition = FlxG.sound.music.time;

		FlxG.sound.music.volume = 1;

		if (vocals != null) vocals.volume = 1;
		if (authorGroup != null)
		{
			modchartTweens.push(FlxTween.tween(authorGroup, { x: FlxG.width }, Conductor.crochet / 1000, { ease: FlxEase.quartIn, startDelay: (Conductor.crochet * 4) / 1000, onComplete: function(twn:FlxTween) {
				authorGroup.kill();
				remove(authorGroup);

				authorGroup.destroy();
				authorGroup = null;

				cleanupTween(twn);
			} }));
		}

		if (startOnTime > 0)
			setSongTime(startOnTime - 500);
		startOnTime = 0;

		if (paused)
		{
			FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();
		}

		camZooming = true;//curSong != 'tutorial';
		super.update(FlxG.elapsed);

		stepHit();
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		FlxTween.tween(timeBar, {alpha: 1}, .5, {ease: FlxEase.circOut, onComplete: cleanupTween});
		FlxTween.tween(timeTxt, {alpha: 1}, .5, {ease: FlxEase.circOut, onComplete: cleanupTween});
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter(), true, songLength);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		Conductor.changeBPM(SONG.bpm);
		if (SONG.needsVoices)
		{
			vocals = new FlxSound();
			vocals.loadEmbedded(Paths.voices(dataPath));

			FlxG.sound.list.add(vocals);
		}

		// FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(dataPath)));
		notes = new FlxTypedGroup<Note>();
		if (worldStrumLineNotes != null)
		{
			worldNotes = new FlxTypedGroup<Note>();
			worldNotes.cameras = [camGame];

			add(worldNotes);
		}
		add(notes);

		var noteData:Array<SwagSection> = SONG.notes;
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
		var noteOffset:Int = ClientPrefs.getPref('noteOffset');

		var file:String = Paths.json('$curSong/events');
		#if sys
		if (FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', curSong).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;
				var noteType:String = songNotes[3];

				switch (noteType) { case 'horse cheese note': { if (!mechanicsEnabled) continue; } }
				if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;

				var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[Std.int(unspawnNotes.length - 1)] : null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, noteAssetsLibrary);

				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = noteType;

				switch (noteType)
				{
					case 'horse cheese note':
					{
						if (horseImages == null)
						{
							trace("PRELOAD HORSES AND THE NOTES");

							CoolUtil.precacheSound('ANGRY');
							Paths.image('horse_cheese_notes');

							var dirPath:String = 'horses/';
							var library:String = 'shared';

							var horsePath:String = Paths.getLibraryPath('$library/images/$dirPath');

							var horseTemp:Array<FlxGraphic> = new Array<FlxGraphic>();
							var assetList:Array<String> = OpenFlAssets.list(IMAGE);

							for (asset in assetList) { if (asset.startsWith(horsePath)) horseTemp.push(Paths.returnGraphic('$library:$asset')); }
							horseImages = horseTemp;
						}
					}
				}
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				if (susLength > 0)
				{
					var floorSus:Int = Math.round(susLength);
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / songSpeed), daNoteData, oldNote, true, false, noteAssetsLibrary);

						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));

						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();

						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress) { sustainNote.x += FlxG.width / 2; } // general offset
						else
						{
							if (middleScroll)
							{
								sustainNote.x += 310;
								if (daNoteData > 1) sustainNote.x += FlxG.width / 2 + 25; // Up and Right
							}
						}
					}
				}
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2;
				} // general offset
				else
				{
					if (middleScroll)
					{
						swagNote.x += 310;
						if (daNoteData > 1) swagNote.x += FlxG.width / 2 + 25; // Up and Right
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType)) noteTypeMap.set(swagNote.noteType, true);
			}
			daBeats += 1;
		}
		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};

				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);

				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime); // No need to sort if there's a single one or none at all
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Popup': { CoolUtil.precacheSound('disconnect'); Paths.image('popup'); }
			case 'Vignette':
				{
					if (vignetteImage == null)
					{
						var imagePath:FlxGraphic = Paths.image('vignette');

						vignetteImage = new FlxSprite().loadGraphic(imagePath, false);
						vignetteImage.antialiasing = ClientPrefs.getPref('globalAntialiasing');

						vignetteImage.setGraphicSize(FlxG.width, FlxG.height);
						vignetteImage.updateHitbox();

						vignetteImage.screenCenter();
						vignetteImage.scrollFactor.set();

						vignetteImage.cameras = [camOther];
						vignetteImage.alpha = 0;

						add(vignetteImage);
					}
				}
			case 'Extend Timer':
				{
					if (timerExtensions == null)
					{
						timerExtensions = new Array<Float>();
					}

					timerExtensions.push(event.strumTime);
					maskedSongLength = timerExtensions[0];
				}

			case 'Change Character':
				{
					var newCharacter:String = event.value2;
					var path:String = Paths.getPreloadPath('characters/$newCharacter.json');

					if (Assets.exists(path))
					{
						var json:Dynamic = Json.parse(Assets.getText(path));
						var asset:FlxGraphic = Paths.image(json.image); // Cache

						trace(asset);
					}
				}
		}

		if (!eventPushedMap.exists(event.event))
			eventPushedMap.set(event.event, true);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		switch (event.event)
		{
			// case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
			//	return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false;
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var isWorldStrumLine:Bool = player > 1;

			var strumLinePushing:FlxTypedGroup<StrumNote> = isWorldStrumLine ? worldStrumLineNotes : strumLineNotes;
			var strumLineSprite:FlxSprite = isWorldStrumLine ? worldStrumLine : strumLine;

			var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
			var targetAlpha:Float = (player < 1 && !ClientPrefs.getPref('opponentStrums')) ? 0 : switch (isWorldStrumLine)
			{
				default: (middleScroll && player < 1) ? .35 : 1;
				case true: .65;
			}

			var babyArrow:StrumNote = new StrumNote(isWorldStrumLine ? strumLineSprite.x : (middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X), strumLineSprite.y, i, isWorldStrumLine ? 0 : shitFlipped ? 1 - player : player, noteAssetsLibrary);
			babyArrow.downScroll = ClientPrefs.getPref('downScroll') && !isWorldStrumLine;

			if (isStoryMode) { babyArrow.alpha = targetAlpha; }
			else
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				modchartTweens.push(FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1,
					{ease: FlxEase.circOut, startDelay: .5 + (.2 * i), onComplete: cleanupTween}));
			}

			switch (player)
			{
				case 1:
					playerStrums.add(babyArrow);
				case 2:
					{
						if (secondOpponentStrums != null)
						{
							babyArrow.texture = 'Pink_Note_Assets';
							babyArrow.scrollFactor.set(1, 1);

							secondOpponentStrums.add(babyArrow);
						}
					}

				default:
					{
						if (middleScroll)
						{
							babyArrow.x += 310;
							if (i > 1)
								babyArrow.x += FlxG.width / 2 + 25; // Up and Right
						}
						opponentStrums.add(babyArrow);
					}
			}

			strumLinePushing.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad, pinkSoldier, duoOpponent];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
					char.colorTween.active = false;
			}

			for (tween in modchartTweens)
				tween.active = false;
			for (timer in modchartTimers)
				timer.active = false;
		}
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals(true);

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad, pinkSoldier, duoOpponent];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
					char.colorTween.active = true;
			}

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;

			paused = false;
			DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter(), startTimer == null ? true : startTimer.finished,
				songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
		}
		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused)
			quickUpdatePresence();

		focused = true;
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused)
			quickUpdatePresence("PAUSED - ", false);

		focused = false;
		super.onFocusLost();
	}

	function resyncVocals(?forceMusic:Bool = false, ?skipOtherBullshitChecks = false):Void
	{
		if (finishTimer != null)
			return;

		var curTime:Float = FlxG.sound.music.time;
		var curVocals:Float = vocals != null ? vocals.time : curTime;

		var isntRestartingSong:Bool = skipOtherBullshitChecks == true || curTime < FlxG.sound.music.length;
		if ((forceMusic == true || (SONG.needsVoices && vocals != null && (curVocals > curTime + vocalResyncTime || curVocals < curTime - vocalResyncTime) && vocals.length > curTime)) && isntRestartingSong)
		{
			trace('resync checks passed');
			// im like 90% sure this yields so i'm force restarting it and caching the current music time, then restarting it
			FlxG.sound.music.play(true);
			FlxG.sound.music.time = curTime;

			if (SONG.needsVoices && vocals != null)
			{
				vocals.play(true);
				vocals.time = curTime;
			}
		}
		if (isntRestartingSong) Conductor.songPosition = curTime;
	}
	override public function update(elapsed:Float)
	{
		var songPosition:Float = Conductor.songPosition;
		var sinkCutscene:Bool = false;

		hitsoundsPlayed = [];

		if (inCutscene) { sinkCutscene = true; }
		else
		{
			var curNote:SwagSection = SONG.notes[curSection];
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);

			if (generatedMusic && curNote != null && !endingSong && !isCameraOnForcedPos) moveCameraSection();
			cancelCameraDelta(boyfriend);

			var cancelDad:Bool = true;
			if (duoOpponent != null)
			{
				if (!dad.animation.name.startsWith('sing')) cancelCameraDelta(duoOpponent, true);
				if (duoOpponent.animation.curAnim != null && duoOpponent.animation.curAnim.name.startsWith('sing')) cancelDad = false;
			}

			if (cancelDad) cancelCameraDelta(dad);
			if (pinkSoldier != null)
				cancelCameraDelta(pinkSoldier);

			var usePlayerDelta:Bool = curNote != null && curNote.mustHitSection;

			var point:FlxPoint = usePlayerDelta ? playerDelta : opponentDelta;
			var multiplier:Float = ClientPrefs.getPref('reducedMotion') ? 0 : cameraOffset;

			var followX:Float = camFollow.x + (point.x * multiplier);
			var followY:Float = camFollow.y + (point.y * multiplier);

			if (secondOpponentDelta != null)
			{
				var newZoom:Float = stageData.defaultZoom;
				if (!usePlayerDelta)
				{
					var secondX:Float = secondOpponentDelta.x;
					var secondY:Float = secondOpponentDelta.y;

					followX += secondX * multiplier;
					followY += secondY * multiplier;

					if (secondX != 0 || secondY != 0)
					{
						followX += 250;
						followY -= 100;

						newZoom = stageData.defaultZoom + .2;
					}
				}
				defaultCamZoom = newZoom;
			}
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, followX, lerpVal), FlxMath.lerp(camFollowPos.y, followY, lerpVal));
		}

		for (shader in shaders) shader.update(elapsed);
		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause && !sinkCutscene)
		{
			persistentUpdate = false;
			persistentDraw = true;

			paused = true;

			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			DiscordClient.changePresence(detailsPausedText, getFormattedSong(), iconP2.getCharacter());
		}
		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			#if debug
			openChartEditor();
			#else
			if (!isStoryMode)
			{
				for (week => data in WeekData.weeksLoaded)
				{
					for (song in data.songs)
					{
						if (song[0] == SONG.song)
						{
							if (StoryMenuState.weekCompleted.exists(week) || data.hideStoryMode)
								openChartEditor();
							break;
						}
					}
				}
			}
			#end
		}

		health = Math.min(health, maxHealth);

		var healthPercent:Float = healthBar.percent;
		var curHealth:Float = shitFlipped ? 100 - healthPercent : healthPercent;

		var hideHUD:Bool = ClientPrefs.getPref('hideHud');
		var iconOffset:Int = 26;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(curHealth, 0, 100, 100, 0) / 100))
			+ (150 * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(curHealth, 0, 100, 100, 0) / 100))
			- (150 * iconP2.scale.x) / 2
			- iconOffset * 2;

		var p2:Character = shitFlipped ? boyfriend : dad;
		var p1:Character = shitFlipped ? dad : boyfriend;

		var p1Group:FlxSpriteGroup = shitFlipped ? dadGroup : boyfriendGroup;
		var p2Group:FlxSpriteGroup = shitFlipped ? boyfriendGroup : dadGroup;

		iconP2.visible = !hideHUD && p2.visible && p2Group.visible;
		iconP1.visible = !hideHUD && p1.visible && p1Group.visible;

		iconP1.alpha = p1.alpha * p1Group.alpha;
		iconP2.alpha = p2.alpha * p2Group.alpha;

		iconP2.setFrameOnPercentage(100 - curHealth);
		iconP1.setFrameOnPercentage(curHealth);

		#if debug
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;

			cancelMusicFadeTween();
			LoadingState.loadAndSwitchState(new CharacterEditorState(SONG.player2), false, true);
		}
		#end

		var elapsedMult:Float = elapsed * 1000;
		var elapsedTicks:Int = FlxG.game.ticks;

		if (startingSong)
		{
			if (startedCountdown)
			{
				songPosition += elapsedMult;
				if (songPosition >= 0)
					startSong();
			}
		}
		else
		{
			songPosition += elapsedMult;
			if (!paused)
			{
				songTime += elapsedTicks - previousFrameTime;
				previousFrameTime = elapsedTicks;
				// Interpolation type beat
				if (Conductor.lastSongPos != songPosition)
				{
					songTime = (songTime + songPosition) / 2;
					Conductor.lastSongPos = songPosition;
				}
				if (updateTime)
				{
					var curTime:Float = songPosition - ClientPrefs.getPref('noteOffset');
					var timeBarType:String = ClientPrefs.getPref('timeBarType');

					var lengthUsing:Float = (maskedSongLength > 0) ? maskedSongLength : songLength;

					curTime = Math.max(curTime, 0);
					songPercent = (curTime / lengthUsing);

					var songCalc:Float = (lengthUsing - curTime);
					if (timeBarType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(Math.max(songCalc / 1000, 0));
					if (timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}
		}

		var lerpSpeed:Float = CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1);

		camGame.zoom = gameZoom + gameZoomAdd; // FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, lerpSpeed);
		camHUD.zoom = hudZoom + hudZoomAdd; // FlxMath.lerp(1, camHUD.zoom, lerpSpeed);

		if (camZooming)
		{
			gameZoom = FlxMath.lerp(defaultCamZoom, gameZoom, lerpSpeed);
			// commented out because i could maybe keep it constant
			// hudZoom = FlxMath.lerp(1, hudZoom, lerpSpeed);
			gameZoomAdd = FlxMath.lerp(0, gameZoomAdd, lerpSpeed);
			hudZoomAdd = FlxMath.lerp(0, hudZoomAdd, lerpSpeed);
		}
		if (vignetteImage != null)
		{
			vignetteImage.setGraphicSize(FlxG.width, FlxG.height);
			vignetteImage.updateHitbox();

			vignetteImage.alpha = FlxMath.lerp(CoolUtil.boolToInt(vignetteEnabled), vignetteImage.alpha, lerpSpeed);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.getPref('noReset') && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = -1;
			trace("RESET = True");
		}
		doDeathCheck();
		if (unspawnNotes[0] != null)
		{
			var weirdAssMap:Map<Note, Note> = new Map<Note, Note>();
			var time:Float = spawnTime;

			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - songPosition <= time)
			{
				var insertingIn:FlxTypedGroup<Note> = notes;
				var dunceNote:Note = unspawnNotes[0];

				if (dunceNote.noteType != null) // FUCK YOU HTML5
				{
					var formattedNoteType:String = Paths.formatToSongPath(dunceNote.noteType);
					switch (formattedNoteType)
					{
						case 'duo-note' | 'both-opponents-note':
						{
							if (!dunceNote.mustPress && worldNotes != null)
							{
								// HOPE THIS WORKS!!!!!!!!!!!
								if (formattedNoteType == 'both-opponents-note')
								{
									var cloneNote:Note = new Note(dunceNote.strumTime, dunceNote.noteData, weirdAssMap.get(dunceNote.prevNote), dunceNote.isSustainNote, dunceNote.inEditor);
									weirdAssMap.set(dunceNote, cloneNote);

									cloneNote.noteType = dunceNote.noteType;
									cloneNote.multSpeed = dunceNote.multSpeed;

									cloneNote.sustainLength = dunceNote.sustainLength;
									cloneNote.colorSwap = dunceNote.colorSwap;

									notes.insert(0, cloneNote);
								}

								dunceNote.reloadNote('', 'Pink_Note_Assets');
								if (dunceNote.isSustainNote)
									dunceNote.flipY = false;

								dunceNote.scrollFactor.set(1, 1);
								insertingIn = worldNotes;
							}
						}
					}
				}
				insertingIn.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (cpuControlled) { bfDance(); }
				else { keyShit(); }
			}
			// this should hopefully fix delayed doubles???? i got no fucking clue
			var opponentNotesToHit:Array<Note> = [];
			var playerNotesToHit:Array<Note> = [];

			var fakeCrochet:Float = Conductor.calculateCrochet(SONG.bpm);// (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumMembers:Array<StrumNote> = (daNote.mustPress ? playerStrums : opponentStrums).members;

				var strumX:Float = strumMembers[daNote.noteData].x;
				var strumY:Float = strumMembers[daNote.noteData].y;

				var strumDirection:Float = strumMembers[daNote.noteData].direction;
				var strumAngle:Float = strumMembers[daNote.noteData].angle;

				var strumScroll:Bool = strumMembers[daNote.noteData].downScroll;
				var strumAlpha:Float = strumMembers[daNote.noteData].alpha;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;

				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				daNote.distance = .45 * (songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed * (strumScroll ? 1 /* Downscroll */ : -1 /* Upscroll */);
				var angleDir = strumDirection * Math.PI / 180;

				if (daNote.copyAngle) daNote.angle = strumDirection - 90 + strumAngle;
				if (daNote.copyAlpha) daNote.alpha = strumAlpha;

				if (daNote.copyX) daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
				if (daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
					// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if (strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;

							daNote.y -= 19;
						}

						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if (strumMembers[daNote.noteData].sustainReduce
					&& daNote.isSustainNote
					&& (daNote.mustPress || !daNote.ignoreNote)
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}
				// Kill extremely late notes and cause misses
				if (songPosition > (noteKillOffset / daNote.lateHitMult) + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				else
				{
					switch (daNote.mustPress)
					{
						case true: { if (cpuControlled && !daNote.blockHit && (daNote.strumTime <= songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.prevNote.wasGoodHit))) playerNotesToHit.push(daNote); }
						default: { if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNotesToHit.push(daNote); }
					}
				}
			});
			if (worldNotes != null)
			{
				var members:Array<StrumNote> = secondOpponentStrums.members;
				worldNotes.forEachAlive(function(daNote:Note)
				{
					var strumX:Float = members[daNote.noteData].x;
					var strumY:Float = members[daNote.noteData].y;

					var strumDirection:Float = members[daNote.noteData].direction;
					var strumAngle:Float = members[daNote.noteData].angle;

					var strumAlpha:Float = members[daNote.noteData].alpha;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;

					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					daNote.distance = -.45 * (songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed; // Upscroll
					var angleDir = strumDirection * Math.PI / 180;

					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;
					if (daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if (daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
					if (daNote.copyY)
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					var center:Float = strumY + Note.swagWidth / 2;
					if (members[daNote.noteData].sustainReduce && daNote.isSustainNote)
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
					// Kill extremely late notes and cause misses
					if (songPosition > (noteKillOffset / daNote.lateHitMult) + daNote.strumTime)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
					else if (daNote.wasGoodHit && !daNote.ignoreNote) { opponentNotesToHit.push(daNote); }
				});
			}

			for (note in opponentNotesToHit) opponentNoteHit(note);
			for (note in playerNotesToHit) goodNoteHit(note);
		}
		Conductor.songPosition = songPosition;
		checkEventNote();
		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();

				FlxG.sound.music.onComplete();
				FlxG.sound.music.onComplete = null;
			}
			if (FlxG.keys.justPressed.TWO)
			{
				// Go 10 seconds into the future :O
				var skipping:Float = songPosition + 10000;

				setSongTime(skipping);
				clearNotesBefore(skipping);

				if (skipping >= FlxG.sound.music.length)
				{
					KillNotes();

					FlxG.sound.music.onComplete();
					FlxG.sound.music.onComplete = null;
				}
			}
		}
		#end
		super.update(elapsed);
	}
	public function updateScore(noZoom:Bool = false)
	{
		var format:String = 'score: $songScore | horse cheeses: $songMisses | rating: $ratingName';
		scoreTxt.text = (ratingName == '?') ? format : '$format (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC';

		if (ClientPrefs.getPref('scoreZoom') && !noZoom)
		{
			if (scoreTxtTween != null)
			{
				scoreTxtTween.cancel();
				cleanupTween(scoreTxtTween);
				scoreTxtTween = null;
			}

			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = scoreTxt.scale.x;

			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, .2, {
				onComplete: function(twn:FlxTween)
				{
					cleanupTween(twn);
					scoreTxtTween = null;
				}
			});
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();
		LoadingState.loadAndSwitchState(new ChartingState(), false, true);

		chartingMode = true;
		DiscordClient.changePresence("Chart Editor", null, null, true);
	}

	function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if ((skipHealthCheck || health <= 0) && !isDead)
		{
			trace('im dying ,.........help me');

			boyfriend.stunned = true;
			if (!chartingMode) deathCounter++;

			paused = true;

			FlxG.sound.music.stop();
			if (vocals != null) vocals.stop();

			persistentUpdate = false;
			persistentDraw = false;

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;

			DiscordClient.changePresence('Game Over - $detailsText', getFormattedSong(false), iconP2.getCharacter());
			GameOverSubstate.characterName = boyfriend.curCharacter;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

			isDead = true;
			return true;
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
				break;

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	function tweenMask(temp:FlxSprite, value:Float)
	{
		maskedSongLength = value;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Hey!':
				{
					var time:Float = Std.parseFloat(value2);
					var value:Int = switch (value1.toLowerCase().trim())
					{
						case 'gf' | 'girlfriend' | '1': 1;
						case 'bf' | 'boyfriend' | '0': 0;

						default: 2;
					};

					if (Math.isNaN(time) || time <= 0) { time = Conductor.crochet / 1000; }
					else { time *= Conductor.crochet / 1000; }

					if (value != 0)
					{
						var characterAnimation:Character = dad.curCharacter.startsWith('gf') ? dad : gf;
						characterAnimation.playAnim('cheer', true);

						characterAnimation.specialAnim = true;
						characterAnimation.heyTimer = time;
					}
					if (value != 1)
					{
						boyfriend.playAnim('hey', true);

						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;
					}
				}
			case 'Set GF Speed':
				{
					var value:Int = Std.parseInt(value1);
					if (Math.isNaN(value))
						value = 1;
					gfSpeed = value;
				}
			case 'Add Camera Zoom':
				{
					if (canZoomCamera())
					{
						var camZoomAdding:Float = Std.parseFloat(value1);
						var hudZoomAdding:Float = Std.parseFloat(value2);

						if (Math.isNaN(camZoomAdding)) camZoomAdding = .015;
						if (Math.isNaN(hudZoomAdding)) hudZoomAdding = .03;

						gameZoomAdd += camZoomAdding;
						hudZoomAdd += hudZoomAdding;
					}
				}
			case 'Popup':
				{
					if (FlxG.random.bool())
					{
						var popup:FlxSprite = new FlxSprite().loadGraphic(Paths.image('popup'));

						var height:Float = (FlxG.height - popup.height) / 2;
						var width:Float = (FlxG.width - popup.width) / 2;

						var offsetY:Float = FlxG.random.float(height, -height);
						var offsetX:Float = FlxG.random.float(width, -width);

						popup.antialiasing = ClientPrefs.getPref('globalAntialiasing');

						popup.cameras = [camOther];
						popup.scale.set(.8, .8);

						popup.updateHitbox();
						popup.screenCenter();

						popup.x += offsetX;
						popup.y += offsetY;

						popup.scrollFactor.set();
						popup.alpha = .7;

						modchartTweens.push(FlxTween.tween(popup, { alpha: 1, "scale.x": 1, "scale.y": 1 }, 1 / 4, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								modchartTimers.push(new FlxTimer().start(4, function(tmr:FlxTimer)
								{
									modchartTweens.push(FlxTween.tween(popup, { alpha: 0, "scale.x": .8, "scale.y": .8 }, 1 / 4,
										{ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween)
										{
											remove(popup);
											popup.destroy();
											cleanupTween(twn);
										}}));
									cleanupTimer(tmr);
								}));
								cleanupTween(twn);
							},
							onUpdate: function(twn:FlxTween)
							{
								popup.updateHitbox();
								popup.screenCenter();

								popup.x += offsetX;
								popup.y += offsetY;
							}
						}));

						add(popup);
						FlxG.sound.play(Paths.sound('disconnect'));
					}
				}
			case 'Vignette':
				{
					var value:Bool = value1.trim().toLowerCase().startsWith('true');
					vignetteEnabled = value;
				}

			case 'Extend Timer':
				{
					if (timerExtensions != null)
					{
						timerExtensions.shift();

						var next:Dynamic = timerExtensions[0];
						modchartTweens.push(FlxTween.num(maskedSongLength, (next != null && next > 0) ? next : songLength, Conductor.crochet / 1000,
							{ease: FlxEase.quintIn, onComplete: cleanupTween}, tweenMask.bind(timeTxt)));
					}
				}
			case 'Subtitles':
				{
					if (subtitlesTxt != null && ClientPrefs.getPref('subtitles'))
					{
						var text:String = value1.trim();
						if (text.length > 0)
						{
							var char:Character = switch (value2.toLowerCase().trim())
							{
								case 'gf' | 'girlfriend': gf;
								case 'dad' | 'opponent': dad;

								default: boyfriend;
							};
							subtitlesTxt.text = text;

							subtitlesTxt.updateHitbox();
							subtitlesTxt.screenCenter();

							var subtitlesY:Float = (healthBar.height + scoreTxt.height + subtitlesTxt.borderSize) * 2;
							var subtitlesSize:Float = subtitlesTxt.size;

							subtitlesTxt.y = switch (ClientPrefs.getPref('downScroll'))
							{
								default: FlxG.height - subtitlesSize - subtitlesY - subtitlesTxt.height;
								case true: subtitlesY + (subtitlesSize * 1.5);
							};

							if (char == gf && gf == null) { subtitlesTxt.color = 0xFFA5004D; }
							else { subtitlesTxt.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]); }

							subtitlesTxt.visible = true;
							add(subtitlesTxt);
						}
						else
						{
							subtitlesTxt.visible = false;
							remove(subtitlesTxt);
						}
					}
				}

			case 'Set Zoom Type':
				{
					var beats:Int = Std.parseInt(value2.trim());
					var type:Int = Std.parseInt(value1.trim());

					camZoomType = Math.isNaN(type) ? 0 : Std.int(Math.min(type, camZoomTypes.length - 1));
					camZoomTypeBeatOffset = Math.isNaN(beats) ? 0 : beats;
				}
			case 'Change Default Zoom':
				{
					var value:Float = Std.parseFloat(value1.trim());
					defaultCamZoom = stageData.defaultZoom + (Math.isNaN(value) ? 0 : value);
				}
			case 'Flash Camera':
				{
					var duration:Float = Std.parseFloat(value1.trim());
					var color:String = value2.trim();

					if (color.length > 1)
					{
						if (!color.startsWith('0x'))
							color = '0xFF$color';
					}
					else
					{
						color = "0xFFFFFFFF";
					}

					if (ClientPrefs.getPref('flashing'))
						camOther.flash(Std.parseInt(color), Math.isNaN(duration) ? 1 : duration, null, true);
				}
			case 'Change Character Visibility':
				{
					var visibility:String = value2.toLowerCase();
					var char:Character = switch (value1.toLowerCase().trim())
					{
						case 'gf' | 'girlfriend': gf;
						case 'dad' | 'opponent': dad;

						default: boyfriend;
					};
					char.visible = visibility.length <= 1 || visibility.startsWith('true');
				}

			case 'Play Sound':
				{
					try
					{
						var sound:Dynamic = Reflect.getProperty(this, value1);
						if (sound != null && Std.isOfType(sound, FlxSound))
							sound.play(true);
					}
					catch (e:Dynamic)
					{
						trace('Unknown sound tried to be played - $e');
					}
				}
			case 'Play Animation':
				{
					// trace('Anim to play: ' + value1);
					var char:Character = switch (value2.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend': boyfriend;
						case 'gf' | 'girlfriend': gf;

						default:
							{
								var val2:Int = Std.parseInt(value2);

								if (Math.isNaN(val2))
									val2 = 0;
								switch (val2)
								{
									case 1: boyfriend;
									case 2: gf;

									default: dad;
								}
							}
					}

					char.playAnim(value1, true);
					char.specialAnim = true;
				}
			case 'Camera Follow Pos':
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1))
						val1 = 0;
					if (Math.isNaN(val2))
						val2 = 0;

					isCameraOnForcedPos = false;
					if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
					{
						camFollow.x = val1;
						camFollow.y = val2;

						isCameraOnForcedPos = true;
					}
				}
			case 'Alt Idle Animation':
				{
					var char:Character = switch (Paths.formatToSongPath(value1))
					{
						case 'boyfriend' | 'bf': boyfriend;
						case 'gf' | 'girlfriend': gf;

						default:
							{
								var val:Int = Std.parseInt(value1);

								if (Math.isNaN(val))
									val = 0;
								switch (val)
								{
									case 1: boyfriend;
									case 2: gf;

									default: dad;
								}
							}
					}

					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}
			case 'Sustain Shake':
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1))
						val1 = 0;
					if (Math.isNaN(val2))
						val2 = 0;

					gameShakeAmount = val1;
					hudShakeAmount = val2;

					doSustainShake();
				}
			case 'Screen Shake':
				{
					if (!ClientPrefs.getPref('reducedMotion'))
					{
						var valuesArray:Array<String> = [value1, value2];
						var targetsArray:Array<FlxCamera> = [camGame, camHUD];

						for (i in 0...targetsArray.length)
						{
							var split:Array<String> = valuesArray[i].split(',');

							var intensity:Float = 0;
							var duration:Float = 0;

							if (split[1] != null)
								intensity = Std.parseFloat(split[1].trim());
							if (split[0] != null)
								duration = Std.parseFloat(split[0].trim());

							if (Math.isNaN(intensity))
								intensity = 0;
							if (Math.isNaN(duration))
								duration = 0;

							if (duration > 0 && intensity != 0)
								targetsArray[i].shake(intensity, duration);
						}
					}
				}

			case 'Change Character':
				{
					var charType:Int = switch (Paths.formatToSongPath(value1))
					{
						case 'gf' | 'girlfriend': 2;
						case 'dad' | 'opponent': 1;

						default:
							{
								var temp:Int = Std.parseInt(value1);
								Math.isNaN(temp) ? 0 : temp;
							}
					}
					var characterPositioning:Character = switch (charType)
					{
						case 1: dad;
						case 2: gf;

						default: boyfriend;
					}

					if (characterPositioning.curCharacter != value2)
					{
						switch (charType)
						{
							default: characterPositioning.setPosition(GF_X, GF_Y);

							case 0: { characterPositioning.setPosition(BF_X, BF_Y); }
							case 1:
								{
									if (dad.curCharacter != value2)
									{
										var wasGf:Bool = dad.curCharacter.startsWith('gf');
										if (!dad.curCharacter.startsWith('gf'))
										{
											characterPositioning.setPosition(DAD_X, DAD_Y);
											if (wasGf && gf != null)
												gf.visible = true;
										}
										else
										{
											if (gf != null)
												gf.visible = false;
											characterPositioning.setPosition(GF_X, GF_Y);
										}
									}
									if (duoOpponent != null)
									{
										duoOpponent.setPosition(DAD_X + DUO_X, DAD_Y + DUO_Y);
										duoOpponent.setCharacter(value2.endsWith('youtooz') ? 'funnybf' : 'funnybf-youtooz');

										startCharacterPos(duoOpponent);
									}
								}
						}

						characterPositioning.setCharacter(value2);
						startCharacterPos(characterPositioning, characterPositioning == dad);
					}
					var iconChanging:HealthIcon = switch (charType)
					{
						default: iconP1;
						case 1: iconP2;
					};

					iconChanging.changeIcon(characterPositioning.healthIcon);
					reloadHealthBarColors();
				}
			case 'Change Scroll Speed':
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1))
						val1 = 1;
					if (Math.isNaN(val2))
						val2 = 0;

					var newValue:Float = switch (songSpeedType)
					{
						default: SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
						case "constant": ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
					}

					if (val2 <= 0) { songSpeed = newValue; }
					else
					{
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								cleanupTween(twn);
								songSpeedTween = null;
							}
						});
					}
				}
		}
	}

	function moveCameraSection():Void
	{
		var section:SwagSection = SONG.notes[curSection];

		if (section == null) return;
		if (gf != null && section.gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);

			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

			tweenCamZoom(true);
			return;
		}
		moveCamera(!section.mustHitSection);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

			tweenCamZoom(true);
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			tweenCamZoom();
		}
	}

	function tweenCamZoom(opponent:Bool = false)
	{
		var start:Float = defaultCamZoom;
		switch (curSong)
		{
			case 'tutorial':
			{
				var target:Float = opponent ? 1.3 : 1;
				if (start != target)
				{
					if (cameraTwn != null)
					{
						cameraTwn.cancel();
						cleanupTween(cameraTwn);
						cameraTwn = null;
					}

					defaultCamZoom = target;
					cameraTwn = FlxTween.num(start, target, Conductor.crochet / 1000, {
						ease: FlxEase.elasticInOut,

						onUpdate: function(twn:FlxTween) { gameZoom = FlxMath.lerp(start, target, twn.scale); },
						onComplete: function(twn:FlxTween)
						{
							cleanupTween(twn);
							cameraTwn = null;
						}
					});
				}
			}
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		trace('finish song please!');

		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.
		var delay:Float = 0;

		if (unspawnNotes.length > 0)
		{
			var last:Note = unspawnNotes[unspawnNotes.length - 1];
			trace(last);
			delay = (Conductor.crochet + (last.strumTime - Conductor.songPosition)) / 1000;
			trace(delay);
		}

		updateTime = false;
		FlxG.sound.music.volume = 0;

		if (vocals != null)
		{
			vocals.volume = 0;
			vocals.pause();
		}
		var noteOffset:Int = ClientPrefs.getPref('noteOffset');

		if (ignoreNoteOffset) { finishCallback(); }
		else { finishTimer = new FlxTimer().start((noteOffset / 1000) + delay, function(tmr:FlxTimer) { finishCallback(); }); }
	}

	public var transitioning = false;

	private function cleanupEndSong(skipTransIn:Bool = false, useValidScore:Bool = true)
	{
		trace('setting mechanics enabled to ${ClientPrefs.getPref('mechanics')}');
		mechanicsEnabled = ClientPrefs.getPref('mechanics');

		if (!transitioning)
		{
			var isValid:Bool = SONG.validScore && useValidScore;
			#if !switch
			if (isValid)
			{
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			}
			#end

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				if (storyPlaylist.length <= 0)
				{
					TitleState.playTitleMusic();
					cancelMusicFadeTween();

					if (isValid) Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

					FlxG.save.flush();
					FlxTransitionableState.skipNextTransIn = skipTransIn;

					CustomFadeTransition.nextCamera = FlxTransitionableState.skipNextTransIn ? camOther : null;
					MusicBeatState.switchState(new StoryMenuState());

					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					SONG = Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');

				FlxTransitionableState.skipNextTransIn = skipTransIn;
				cancelMusicFadeTween();

				CustomFadeTransition.nextCamera = FlxTransitionableState.skipNextTransIn ? camOther : null;

				FreeplayState.exitToFreeplay();
				TitleState.playTitleMusic();

				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	private function doShitAtTheEnd():Void
	{
		trace('yaaaaay');
		switch (curSong)
		{
			case 'banana': startVideo('minion_fucking_dies', true);
			case 'braindead':
			{
				switch (ClientPrefs.getPref('flashing'))
				{
					case true: startVideo('sexy_anthony_1', true);
					default: cleanupEndSong();
				}
			}
			case 'kleptomaniac' | 'funny-duo':
			{
				switch (isStoryMode)
				{
					case true: startVideo(switch (curSong)
						{
							case 'funny-duo': 'bf_fucking_dies';
							default: 'animation_relapse';
						}, true);
					default: cleanupEndSong();
				}
			}

			default: cleanupEndSong();
		}
	}
	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!(startingSong || cpuControlled))
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength && !daNote.hitCausesMiss)
					health -= daNote.missHealth * healthLoss;
			});

			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength && !daNote.hitCausesMiss)
					health -= daNote.missHealth * healthLoss;
			}
			if (doDeathCheck())
				return;
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		var achievement:Achievement = null;
		if (isStoryMode)
		{
			campaignMisses += songMisses;
			campaignScore += songScore;

			if (storyMisses != null) storyMisses.set(curSong, songMisses);
			storyPlaylist.remove(storyPlaylist[0]);
			if (storyPlaylist.length <= 0 && !ClientPrefs.getGameplaySetting('botplay', false))
			{
				if (storyDifficultyText != CoolUtil.defaultDifficulties[0])
				{
					var curWeek:String = WeekData.weeksList[storyWeek];

					StoryMenuState.weekCompleted.set(curWeek, true);
					trace(curWeek);

					var achievementName:String = switch (curWeek)
					{
						case 'trio': 'week2';
						default: null;
					};
					FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					switch (curWeek)
					{
						case 'funny':
						{
							if (storyMisses != null)
							{
								var total:Int = campaignMisses;

								if (storyMisses.exists('kleptomaniac') && storyDifficulty == 2) total -= Std.int(Math.min(storyMisses.get('kleptomaniac'), AchievementsState.kleptomaniacAllowedMisses));
								if (total <= 0) achievement = new Achievement('week1', camOther);
							}
						}
						case 'trio':
						{
							trace('unlock extra shitssssss');
							for (name in FreeplayState.panelKeys)
							{
								trace('unlock $name');
								if (!FreeplayState.freeplaySectionUnlocked(name)) FreeplayState.unlocked.set(name, true);
							}
							FlxG.save.data.freeplayUnlocked = FreeplayState.unlocked;
						}
					}
					if (achievementName != null && campaignMisses <= 0) achievement = new Achievement(achievementName, camOther);
				}
			}
		}
		if (ClientPrefs.getPref("framerate") == 420)
		{
			trace('GAMER FPS');
			var dopeAchievement:Achievement = new Achievement('WEED', camOther, false, null, null, null, achievement != null ? (Achievement.padding + achievement.bg.height) : 0);

			if (achievement == null) { achievement = dopeAchievement; }
			else { add(dopeAchievement); }
		}

		if (achievement != null)
		{
			if (achievement.finished)
			{
				achievement.destroy();
				achievement = null;

				doShitAtTheEnd();
			}
			else
			{
				achievement.onFinish = doShitAtTheEnd;
				add(achievement);
			}
		}
		else { doShitAtTheEnd(); }
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];

			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0;
	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		if (vocals != null) vocals.volume = 1;
		var comboOffset:Array<Int> = ClientPrefs.getPref('comboOffset');

		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
		var hideHUD:Bool = ClientPrefs.getPref('hideHud');

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.getPref('ratingOffset'));
		var placement:String = Std.string(combo);
		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);
		var score:Int = daRating.score;

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;

		if (!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		if (!cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;

				RecalculateRating();
			}
		}

		if (daRating.noteSplash && !note.noteSplashDisabled) spawnNoteSplashOnNote(note);
		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);

		coolText.visible = false;
		coolText.alpha = 0;

		coolText.screenCenter(Y);
		coolText.x = FlxG.width * .35;

		if (shitFlipped) coolText.x = FlxG.width - coolText.x;
		//
		var comboSpr:FlxSprite = null;
		var rating:FlxSprite = null;

		var halfCrochet:Float = Conductor.crochet / 500;
		var tween:Float = Conductor.crochet / 1000;

		if (showCombo && combo >= 10)
		{
			comboSpr = new FlxSprite().loadGraphic(Paths.image('combo', otherAssetsLibrary));

			comboSpr.cameras = [ camHUD ];
			comboSpr.screenCenter(Y);

			comboSpr.acceleration.y = 200;
			comboSpr.velocity.y -= 140;

			comboSpr.visible = !hideHUD;

			comboSpr.x = coolText.x - 40 + comboOffset[5];
			comboSpr.y -= comboOffset[4];

			comboSpr.velocity.x += FlxG.random.int(1, 10);
			comboSpr.antialiasing = globalAntialiasing;

			comboSpr.setGraphicSize(Std.int(comboSpr.width * switch (introKey)
			{
				case 'compressed': .7;
				default: .5;
			}));
			comboSpr.updateHitbox();
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (showRating)
		{
			rating = new FlxSprite().loadGraphic(Paths.image(daRating.image, otherAssetsLibrary));

			rating.cameras = [camHUD];
			rating.screenCenter(Y);

			rating.x = coolText.x - 40;
			rating.y -= 60;

			rating.acceleration.y = 550;
			rating.velocity.y -= 140;

			rating.visible = !hideHUD;

			rating.x += comboOffset[0];
			rating.y -= comboOffset[1];

			rating.antialiasing = globalAntialiasing;
			rating.setGraphicSize(Std.int(rating.width * .7));

			rating.updateHitbox();
			insert(members.indexOf(strumLineNotes), rating);
		}
		if (showComboNum)
		{
			var seperatedScore:Array<Int> = [];
			if (combo >= 1000)
				seperatedScore.push(Math.floor(combo / 1000) % 10);

			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);

			seperatedScore.push(combo % 10);
			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('num$i', otherAssetsLibrary));
				numScore.antialiasing = globalAntialiasing;

				numScore.cameras = [camHUD];
				numScore.screenCenter();

				numScore.x = coolText.x + (43 * daLoop) - 90;
				numScore.y += 80;

				numScore.x += comboOffset[2];
				numScore.y -= comboOffset[3];

				numScore.antialiasing = globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * switch (introKey)
				{
					case 'compressed': .5;
					default: 1;
				}));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.visible = !hideHUD;

				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				// if (combo >= 10 || combo == 0)
				if (showComboNum) insert(members.indexOf(strumLineNotes), numScore);
				modchartTweens.push(FlxTween.tween(numScore, { alpha: 0 }, tween, {
					onComplete: function(tween:FlxTween)
					{
						remove(numScore);
						numScore.destroy();
						cleanupTween(tween);
					},
					startDelay: halfCrochet
				}));
				daLoop++;
			}
		}
		modchartTweens.push(FlxTween.tween(coolText, { alpha: 0 }, tween, { onComplete: function(twn:FlxTween) {
			if (rating != null)
			{
				remove(rating);
				rating.destroy();
			}
			if (comboSpr != null)
			{
				remove(comboSpr);
				comboSpr.destroy();
			}

			remove(coolText);
			coolText.destroy();
			cleanupTween(twn);
		}, startDelay: Conductor.crochet / 500 }));

		if (comboSpr != null) modchartTweens.push(FlxTween.tween(comboSpr, { alpha: 0 }, tween, { onComplete: cleanupTween, startDelay: halfCrochet }));
		if (rating != null) modchartTweens.push(FlxTween.tween(rating, { alpha: 0 }, tween, { startDelay: tween, onComplete: cleanupTween }));
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!(cpuControlled || paused) && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.getPref('controllerMode')))
		{
			if (!(boyfriend.stunned || endingSong) && generatedMusic)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.getPref('ghostTapping');
				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				// var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;
				var sortedNotesList:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if (daNote.noteData == key) sortedNotesList.push(daNote);
						canMiss = true;
					}
				});

				sortedNotesList.sort(sortHitNotes);
				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);

								doubleNote.destroy();
							}
							else { notesStopped = true; }
						}
						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else if (canMiss) { noteMissPress(key); }
				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (strumsBlocked[key] != true &&spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		// trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		var controllerMode:Bool = ClientPrefs.getPref('controllerMode');
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
					goodNoteHit(daNote);
			});
			if (!endingSong)
				bfDance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}
	function noteMiss(daNote:Note):Void
	{
		// You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		combo = 0;
		health -= daNote.missHealth * healthLoss;

		if (instakillOnMiss)
		{
			if (vocals != null) vocals.volume = 0;
			doDeathCheck(true);
		}

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		if (vocals != null) vocals.volume = 0;

		songScore -= 10;
		totalPlayed++;

		RecalculateRating(true);

		var char:Character = daNote.gfNote ? gf : boyfriend;
		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}
		quickUpdatePresence();
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.getPref('ghostTapping'))
			return;
		if (!boyfriend.stunned)
		{
			health -= .05 * healthLoss;
			if (instakillOnMiss)
			{
				if (vocals != null) vocals.volume = 0;
				doDeathCheck(true);
			}
			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
				gf.playAnim('sad');

			combo = 0;
			songScore -= 10;

			if (!endingSong)
				songMisses++;

			totalPlayed++;
			RecalculateRating(true);

			if (vocals != null) vocals.volume = 0;
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, .2));

			if (boyfriend.hasMissAnimations) boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			quickUpdatePresence();
		}
	}
	function playCharacterAnim(?char:Character = null, animToPlay:String, note:Note):Bool
	{
		if (char != null && !char.specialAnim)
		{
			var curAnim:FlxAnimation = char.animation.curAnim;
			var isSingAnimation:Bool = false;

			if (curAnim != null && !curAnim.name.endsWith('miss')) { for (anim in singAnimations) { if (curAnim.name.startsWith(anim)) { isSingAnimation = true; break; } } }

			var canOverride:Bool = curAnim == null || char.lastNoteHit == null || curAnim.finished || !isSingAnimation;
			if (canOverride || char.lastNoteHit.noteData == note.noteData || (!note.isSustainNote && ((char.lastNoteHit.strumTime < note.strumTime) || (char.lastNoteHit.strumTime == note.strumTime && note.sustainLength > char.lastNoteHit.sustainLength))))
			{
				if (!note.isSustainNote || canOverride) char.lastNoteHit = note;

				char.playAnim(animToPlay, true);
				char.holdTimer = 0;

				return true;
			}
		}
		return false;
	}

	function opponentNoteHit(note:Note):Void
	{
		var formattedNoteType:String = Paths.formatToSongPath(note.noteType);
		var isAlternative:Bool = false;

		var strumsHit:Array<Int> = [ 1 ];
		var isEndNote:Bool = note.animation.curAnim.name.endsWith('end');

		if (formattedNoteType == 'hey!')
		{
			switch (dad.curCharacter)
			{
				default:
				{
					if (dad.animOffsets.exists('hey'))
					{
						dad.playAnim('hey', true);

						dad.specialAnim = true;
						dad.heyTimer = .6;
					}
				}
			}
		}
		else if (!note.noAnimation)
		{
			var chars:Array<Character> = [ dad ];
			var altAnim:String = '';

			var section:SwagSection = SONG.notes[curSection];
			if (section != null)
			{
				if ((section.altAnim || formattedNoteType == 'alt-animation') && !section.gfSection)
					altAnim = note.animSuffix;
			}
			switch (formattedNoteType)
			{
				case 'duo-note' | 'both-opponents-note':
				{
					var isDuoNote:Bool = formattedNoteType == 'duo-note';

					if (isDuoNote) chars = [];
					switch (curSong)
					{
						case 'squidgames': { isAlternative = true; chars.push(pinkSoldier); if (isDuoNote) strumsHit = []; strumsHit.push(2); }
						case 'abrasive': { chars.push(duoOpponent); }
					}
				}
			}

			if (note.gfNote) chars = [ gf ];
			if (!isEndNote)
			{
				var leData:Int = Std.int(Math.abs(note.noteData));
				for (char in chars)
				{
					if (char != null)
					{
						var didPlay:Bool = playCharacterAnim(char, singAnimations[leData] + altAnim, note);
						if (didPlay)
						{
							var camDelta:FlxPoint = getCameraDelta(leData);

							if (isAlternative && secondOpponentDelta != null) { secondOpponentDelta = camDelta; }
							else { opponentDelta = camDelta; }
						}
					}
				}
			}
		}

		if (vocals != null) vocals.volume = 1;
		var time:Float = .15;

		if (note.isSustainNote && !isEndNote) time *= 2;
		if (ClientPrefs.getPref('mechanics'))
		{
			var difficultyClamp = Math.max(storyDifficulty, 1);

			var fixedDrain:Float = healthDrain * (difficultyClamp / 3);
			var fixedDrainCap:Float = healthDrainCap / difficultyClamp;

			var drainDiv:Dynamic = healthDrainMap.exists(curSong) ? healthDrainMap.get(curSong) : null;
			if (drainDiv != null && drainDiv[1] <= storyDifficulty && !note.isSustainNote)
			{
				var divider:Float = drainDiv[0];
				if (health > fixedDrainCap)
					health = Math.max(health - (fixedDrain / divider), fixedDrainCap);
			}
		}

		for (strum in strumsHit) StrumPlayAnim(strum, Std.int(Math.abs(note.noteData)), time);
		note.hitByOpponent = true;

		if (!note.isSustainNote)
		{
			note.kill();

			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			var formattedNoteType:String = Paths.formatToSongPath(note.noteType);
			var leData:Int = Std.int(Math.abs(note.noteData));

			if (Hitsound.canPlayHitsound() && !(note.hitsoundDisabled || (hitsoundsPlayed != null && hitsoundsPlayed.contains(leData)))) { Hitsound.play(); if (hitsoundsPlayed != null) hitsoundsPlayed.push(leData); }
			if (note.hitCausesMiss)
			{
				noteMiss(note);
				quickUpdatePresence();

				if (!note.noteSplashDisabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
				switch (formattedNoteType)
				{
					case 'horse-cheese-note': // horse cheese note
					{
						totalShitsFailed++;
						shitsFailedLol++;

						if (dad.animOffsets.exists('horsecheese'))
						{
							dad.playAnim('horsecheese', true);
							dad.specialAnim = true;
						}
						modchartTimers.push(new FlxTimer().start(1 / 20, function(tmr:FlxTimer)
						{
							if (horseImages != null)
							{
								var roll:FlxGraphic = FlxG.random.getObject(horseImages);
								var width = FlxG.width * FlxG.random.float(.4, .8);

								var horsey:FlxSprite = new FlxSprite().loadGraphic(roll);
								FlxG.sound.play(Paths.sound("ANGRY"), 1);

								horsey.setGraphicSize(Std.int(width), Std.int(width * FlxG.random.float(.1, 2)));
								horsey.cameras = [camOther];

								horsey.antialiasing = ClientPrefs.getPref('globalAntialiasing');

								horsey.updateHitbox();
								horsey.screenCenter();

								horsey.y += (FlxG.height / 2) * FlxG.random.float(-1, 1);
								horsey.x += (FlxG.width / 2) * FlxG.random.float(-1, 1);

								horsey.angle = FlxG.random.int(-360, 360);

								horsey.flipY = FlxG.random.bool(20);
								horsey.flipX = FlxG.random.bool();

								horsey.alpha = FlxG.random.float(.9);
								add(horsey);

								modchartTweens.push(FlxTween.tween(horsey, {alpha: 0}, FlxG.random.float(5, 20), {
									ease: FlxEase.sineInOut,
									onComplete: function(twn:FlxTween)
									{
										shitsFailedLol--;
										horsey.kill();

										remove(horsey);
										horsey.destroy();

										cleanupTween(twn);
									}
								}));
							}
							if (boyfriend.animOffsets.exists('hurt'))
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
							cleanupTimer(tmr);
						}));
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo = Std.int(Math.min(combo + 1, 9999));
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			var isEndNote:Bool = note.animation.curAnim.name.endsWith('end');
			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + switch (formattedNoteType)
				{
					case 'alt-animation': note.animSuffix;
					default: '';
				};

				var char:Character = note.gfNote ? gf : boyfriend;
				if (!isEndNote)
				{
					var didPlay:Bool = playCharacterAnim(char, animToPlay, note);
					if (didPlay) playerDelta = getCameraDelta(leData);
				}
				if (formattedNoteType == 'hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);

						boyfriend.specialAnim = true;
						boyfriend.heyTimer = .6;
					}
					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);

						gf.specialAnim = true;
						gf.heyTimer = .6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = .15;
				if (note.isSustainNote && !isEndNote)
					time += .15;

				StrumPlayAnim(0, Std.int(Math.abs(note.noteData)), time);
			}
			else
			{
				var spr = playerStrums.members[note.noteData];
				if (spr != null) spr.playAnim('confirm', true);
			}

			note.wasGoodHit = true;

			if (vocals != null) vocals.volume = 1;
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
		quickUpdatePresence();
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.getPref('noteSplashes') && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}
	inline public static function getNoteSplash():String
	{
		var skin:String = 'noteSplashes';

		if (SONG.splashSkin != null && SONG.splashSkin.length > 0) skin = SONG.splashSkin;
		return skin;
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = getNoteSplash();

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;

		if (data >= 0 /* && data < ClientPrefs.arrowHSV.length */)
		{
			// hue = ClientPrefs.arrowHSV[data][0] / 360;
			// sat = ClientPrefs.arrowHSV[data][1] / 100;
			// brt = ClientPrefs.arrowHSV[data][2] / 100;

			if (note != null)
			{
				skin = note.noteSplashTexture;

				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);

		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy()
	{
		var application:Application = Application.current;
		if (!ClientPrefs.getPref('controllerMode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		if (application != null)
		{
			var meta:Map<String, String> = application.meta;
			if (meta != null && meta.exists('name')) application.window.title = meta.get('name');
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.fadeTween != null)
			{
				FlxG.sound.music.fadeTween.cancel();
				FlxG.sound.music.fadeTween.destroy();
			}
			FlxG.sound.music.fadeTween = null;
		}
	}

	var lastStepHit:Int = -1;

	function canZoomCamera():Bool
	{
		return camZooming && ClientPrefs.getPref('camZooms'); // && FlxG.camera.zoom < 1.35;
	}

	function getStretchValue(value:Bool):Float
	{
		return value ? -1 : .5;
	}

	function doSustainShake()
	{
		if (!ClientPrefs.getPref('reducedMotion'))
		{
			var stepCrochet:Float = Conductor.stepCrochet / 1000;
			if (gameShakeAmount > 0)
				camGame.shake(gameShakeAmount, stepCrochet);
			if (hudShakeAmount > 0)
				camHUD.shake(hudShakeAmount, stepCrochet);
		}
	}

	function cleanupTween(?twn:FlxTween)
	{
		if (modchartTweens.contains(twn))
			modchartTweens.remove(twn);
		if (twn != null)
		{
			twn.active = false;
			twn.destroy();
		}
	}

	function cleanupTimer(?tmr:FlxTimer)
	{
		if (modchartTimers.contains(tmr))
			modchartTimers.remove(tmr);
		if (tmr != null)
		{
			tmr.active = false;
			tmr.destroy();
		}
	}

	override function stepHit()
	{
		super.stepHit();

		var songPosition:Float = Conductor.songPosition - Conductor.offset;
		if (songPosition >= 0 && Conductor.songPosition <= FlxG.sound.music.length && (Math.abs(FlxG.sound.music.time - songPosition) > vocalResyncTime && FlxG.sound.music.length > songPosition && FlxG.sound.music.time < FlxG.sound.music.length && FlxG.sound.music.playing) || (SONG.needsVoices && vocals != null && Math.abs(vocals.time - songPosition) > vocalResyncTime && vocals.length > songPosition && vocals.time < vocals.length && vocals.time < FlxG.sound.music.length && vocals.playing))
			resyncVocals();
		if (curStep == lastStepHit)
			return;

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		if (zoomFunction != null && canZoomCamera() && !zoomFunction[0])
			zoomFunction[1]();

		doSustainShake();
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	function iconBop(beat:Int = 0)
	{
		var crochetDiv:Float = 1300;
		if (beat % gfSpeed == 0)
		{
			var stretchBool:Bool = (beat % (gfSpeed * 2)) == 0;

			var stretchValueOpponent:Float = getStretchValue(!stretchBool);
			var stretchValuePlayer:Float = getStretchValue(stretchBool);

			var angleValue:Float = 15 * FlxMath.signOf(stretchValuePlayer);
			var scaleValue:Float = .4;

			var scaleDefault:Float = 1.1;

			iconP1.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValuePlayer));
			iconP2.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValueOpponent));

			modchartTweens.push(FlxTween.angle(iconP1, -angleValue, 0, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));
			modchartTweens.push(FlxTween.angle(iconP2, angleValue, 0, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));

			modchartTweens.push(FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));
			modchartTweens.push(FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority) return 1;
		else if (!a.lowPriority && b.lowPriority) return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}
	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) return;
		if (generatedMusic)
		{
			if (worldNotes != null) worldNotes.sort(FlxSort.byY, FlxSort.DESCENDING);
			notes.sort(FlxSort.byY, ClientPrefs.getPref('downScroll') ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		iconBop(curBeat);

		if (zoomFunction != null && canZoomCamera() && zoomFunction[0])
			zoomFunction[1]();

		switch (curSong)
		{
			case 'banana':
			{
				// switch (curBeat)
				// {
				// 	case 256: defaultCamZoom = stageData.defaultZoom + .35;
				// 	case 288: defaultCamZoom = stageData.defaultZoom;
				// }
				if (curBeat >= 252 && !bananaStrumsHidden)
				{
					bananaStrumsHidden = true;
					for (strumNote in opponentStrums.members)
						modchartTweens.push(FlxTween.tween(strumNote, {alpha: 0}, Conductor.crochet / 500, {ease: FlxEase.cubeIn,
							onComplete: cleanupTween}));
				}
			}
		}

		// iconP1.scale.set(1.2, 1.2);
		// iconP2.scale.set(1.2, 1.2);

		// iconP1.updateHitbox();
		// iconP2.updateHitbox();

		groupDance(gfGroup, curBeat);
		groupDance(boyfriendGroup, curBeat);
		groupDance(dadGroup, curBeat);

		stageDance(curBeat);
		lastBeatHit = curBeat;
	}
	override function sectionHit()
	{
		super.sectionHit();

		var section:SwagSection = SONG.notes[curSection];
		if (section != null && section.changeBPM) Conductor.changeBPM(section.bpm);
	}

	function StrumPlayAnim(player:Int, id:Int, time:Float)
	{
		var strumLine:FlxTypedGroup<StrumNote> = switch (player)
		{
			case 2: worldStrumLineNotes;
			case 1: strumLineNotes;

			default: playerStrums;
		};

		var spr:StrumNote = strumLine.members[id];
		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(noZoom:Bool = false)
	{
		if (totalPlayed <= 0) { ratingName = '?'; } // Prevent divide by 0
		else
		{
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

			// Rating Name
			if (ratingPercent >= 1)
			{
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingName = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		setRating();
		updateScore(noZoom);
	}
	function setRating()
	{
		// Rating FC
		ratingFC = "";
		if (songMisses > 0)
		{
			if (songMisses >= 10) { ratingFC = (songMisses > 50) ? 'kill yourself immediatly' : 'a rather large issue of skill'; return; }
			ratingFC = "shit fart";
			return;
		}

		if ((bads + horsedogs) > 0) { ratingFC = "borb combo"; return; }

		if (googs > 0) { ratingFC = "googulus combo"; return; }
		if (funnies > 0) { ratingFC = "shitfartcombo"; return; }
	}
}