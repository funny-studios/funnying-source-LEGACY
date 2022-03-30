package;

import openfl.utils.AssetType;
import flixel.animation.FlxAnimation;
import haxe.macro.Expr.Case;
#if (desktop && !neko)
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
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
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
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
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import StageData;
import DialogueBox;

#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['horse dog phase 2', .2], //From 0% to 19%
		['horse dog', .4], //From 20% to 39%
		['kill yourself', .5], //From 40% to 49%
		['am busy', .6], //From 50% to 59%
		['fuck yo u', .7], //From 60% to 69%
		['Goog', .8], //From 70% to 79%
		['grangt', .9], //From 80% to 89%
		['Funny!', 1], //From 90% to 99%
		['standing ovation', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	// public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	// public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	// public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	// public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	// public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var modchartTweens:Array<FlxTween> = new Array();
	public var modchartTimers:Array<FlxTimer> = new Array();
	//public var modchartSounds:Map<String, FlxSound> = new Map();
	#else
	public var modchartTweens:Array<FlxTween> = new Array<FlxTween>();
	public var modchartTimers:Array<FlxTimer> = new Array<FlxTimer>();
	//public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	#end

	public var stageData:StageFile;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var DUO_X = -325;
	public var DUO_Y = 125;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var stageGroup:FlxTypedGroup<BGSprite>;

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var worldStrumLine:FlxSprite;
	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var worldStrumLineNotes:FlxTypedGroup<StrumNote>;
	public var worldNotes:FlxTypedGroup<Note>;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;

	public var opponentStrums:FlxTypedGroup<StrumNote>;

	public var secondOpponentStrums:FlxTypedGroup<StrumNote>;

	public var duoOpponent:Character;
	public var pinkSoldier:Character;

	public var bgDancers:BGSprite;
	public var fgDancers:BGSprite;
	public var funnyGF:BGSprite;

	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var camZoomType:Int = 0;
	public var camZoomTypes:Array<Array<Dynamic>>;

	private var losingPercent:Float = 20;
	private var vocalResyncTime:Int = 20;

	var dialogue:Array<String> = [];
	var dialogueJson:DialogueFile = null;

	var cameraOffset:Float = 25;
	var secondOpponentDelta:FlxPoint;

	var opponentDelta:FlxPoint;
	var playerDelta:FlxPoint;

	var bananaStrumsHidden:Bool = false;

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

	public var introAssetsPrefix:String = '';
	public var introAssetsSuffix:String = '';

	public var defaultCamZoom:Float = 1.05;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	private var healthDrainCap:Float = 1 / 2;
	private var healthDrain:Float = 1 / 45;

	public var inCutscene:Bool = false;
	var timerExtensions:Array<Float>;

	var vignetteEnabled:Bool = false;
	var vignetteImage:FlxSprite;

	var subtitlesTxt:FlxText;

	var gameShakeAmount:Float = 0;
	var hudShakeAmount:Float = 0;

	var maskedSongLength:Float = -1;
	var songLength:Float = 0;

	var horseImages:Array<String>;
	#if (desktop && !neko)
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public static var instance:PlayState;
	public static var focused:Bool = true;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	override public function create()
	{
		instance = this;

		opponentDelta = new FlxPoint();
		playerDelta = new FlxPoint();

		camZoomType = 0;
		// [ On Beat (bool), Function ]
		camZoomTypes = [
			[ true, function() {
				if (curBeat % 4 == 0)
				{
					FlxG.camera.zoom += .015;
					camHUD.zoom += .03;
				}
			} ],
			[ true, function() {
				if (curBeat % 2 == 0)
				{
					FlxG.camera.zoom += .015;
					camHUD.zoom += .03;
				}
			} ],
			[ true, function() {
				FlxG.camera.zoom += .015;
				camHUD.zoom += .03;
			} ],
			// Funny Guy Snog
			[ true, function() {
				return;
			} ],

			[ false, function() {
				var beatDiv:Dynamic = switch (curStep % 32)
				{
					case 0 | 3 | 6 | 10 | 14 | 28: 1;

					case 16 | 17 | 18 | 19 | 22 | 23 | 24 | 25 | 30: 4;
					case 7 | 11 | 31: -3;

					default: false;
				};
				if (beatDiv != false)
				{
					FlxG.camera.zoom += .015 / beatDiv;
					camHUD.zoom += .03 / beatDiv;
				}
			} ],
			[ false, function() {
				var beatDiv:Dynamic = switch (curStep % 16)
				{
					case 0 | 2 | 4 | 6 | 8 | 10 | 12: 1;

					case 1 | 3 | 5 | 7 | 9 | 11: -Math.PI / 2;
					case 13 | 14 | 15: -3;

					default: false;
				};
				if (beatDiv != false)
				{
					FlxG.camera.zoom += .015 / beatDiv;
					camHUD.zoom += .03 / beatDiv;
				}
			} ],
			[ false, function() {
				var beatDiv:Dynamic = switch (curStep % 32)
				{
					case 0 | 3 | 4 | 7 | 8 | 11 | 12 | 15 | 16 | 18 | 20 | 22 | 23 | 24 | 27 | 28 | 30 | 31: 2;
					default: false;
				};
				if (beatDiv != false)
				{
					FlxG.camera.zoom += .015 / beatDiv;
					camHUD.zoom += .03 / beatDiv;
				}
			} ]
		];

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null) SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if (desktop && !neko)
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? 'Story Mode: ${WeekData.getCurrentWeek().weekName}' : 'Freeplay';
		detailsText += ' - ${getFormattedSong(false)}';

		// String for when the game is paused
		detailsPausedText = 'Paused - $detailsText';
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if (PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			curStage = switch (songName)
			{
				case 'tutorial': 'stage-compressed';

				case 'gastric-bypass': 'grass';
				case 'kleptomaniac': 'hell';

				case 'cervix': 'youtooz';
				case 'relapse': 'relapse';

				case 'squidgames': 'squidgame';
				case 'banana': 'minion';

				case 'braindead': 'mspaint';
				default: 'stage';
			}
		}

		stageData = StageData.getStageFile(curStage);
		if (stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		stageGroup = new FlxTypedGroup<BGSprite>();
		switch (curStage)
		{
			case 'stage': // Tutorial (Original)
			{
				var bg:BGSprite = new BGSprite('stageback', -600, -200);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
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
			case 'stage-compressed': // Tutorial
			{
				var bg:BGSprite = new BGSprite('stageback', -600, -200);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
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
				var bg:BGSprite = new BGSprite('grass', -500, 0);

				bg.setGraphicSize(Std.int(bg.width * 4));
				bg.updateHitbox();

				add(bg);
			}
			case 'hell': // Evil BF
			{
				var bg:BGSprite = new BGSprite('hell', -600, -300);

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
				if (!ClientPrefs.lowQuality)
				{
					duoOpponent = new Character(0, 0, SONG.player2.endsWith('youtooz') ? 'funnybf' : 'funnybf-youtooz');
					funnyGF = new BGSprite('background/gametoons-gf', 250, 300, 1, 1, [ 'idle' ]);

					stageGroup.add(funnyGF);
					if (songName == 'funny-duo')
					{
						fgDancers = new BGSprite('background/funnyduofgcharacters', -250, 400, .5, .25, [ 'foreground characters' ]);
						bgDancers = new BGSprite('background/funnyduobgcharacters', 0, 125, 1, 1, [ 'background characters' ]);

						bgDancers.setGraphicSize(Std.int(bgDancers.width * .8));
						fgDancers.setGraphicSize(Std.int(fgDancers.width * .8));

						fgDancers.updateHitbox();
						bgDancers.updateHitbox();

						stageGroup.add(fgDancers);
						stageGroup.add(bgDancers);
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
			case 'squidgame': // Squid Games
			{
				var bg:BGSprite = new BGSprite('back', -420, -220);

				pinkSoldier = new Character(75, -140, "pinksoldier");
				dadGroup.add(pinkSoldier);

				bg.setGraphicSize(Std.int(bg.width * 1.5));
				bg.updateHitbox();

				add(bg);
			}

			case 'mspaint':
			{
				var bg:BGSprite = new BGSprite('mspaint', -600, 100);

				bg.setGraphicSize(Std.int(bg.width * 1.5));
				bg.updateHitbox();

				add(bg);
			}
		}

		if (bgDancers != null) add(bgDancers);
		if (funnyGF != null) add(funnyGF);

		if (curStage == 'squidgame') { secondOpponentStrums = new FlxTypedGroup<StrumNote>(); secondOpponentDelta = new FlxPoint(); }
		else { add(gfGroup); }

		add(dadGroup);
		add(boyfriendGroup);

		// STAGE SCRIPTS

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) {
			gfVersion = switch (curStage)
			{
				case 'relapse': '';
				default: 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		gf = new Character(0, 0, gfVersion);
		if (gfVersion != null && gfVersion.length > 0)
		{
			startCharacterPos(gf);

			gf.scrollFactor.set(.95, .95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);

		if (pinkSoldier != null) { startCharacterPos(pinkSoldier); dadGroup.add(pinkSoldier); }
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
		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);

		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}

		var file:String = Paths.json('$songName/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) dialogueJson = DialogueBox.parseDialogue(file);

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		if (secondOpponentStrums != null)
		{
			worldStrumLine = new FlxSprite(pinkSoldier.x - 50, pinkSoldier.y - 100).makeGraphic(FlxG.width, 10);
			worldStrumLine.scrollFactor.set(1, 1);
		}

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 0, 400, "", 32);
		timeTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;

		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;

		if (ClientPrefs.timeBarType == 'Song Name') timeTxt.text = SONG.song;
		if (ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		updateTime = showTime;
		timeBarBG = new AttachedSprite('timeBar');

		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);

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

		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;

		timeBar.visible = showTime;

		add(timeBar);
		add(timeTxt);

		timeBarBG.sprTracker = timeBar;
		// yes...
		if (ClientPrefs.subtitles)
		{
			subtitlesTxt = new FlxText(0, 0, FlxG.width, "", 32);
			subtitlesTxt.setFormat(Paths.font("comic.ttf"), subtitlesTxt.size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

			subtitlesTxt.bold = true;
			subtitlesTxt.scrollFactor.set();

			subtitlesTxt.borderSize = 2;
			subtitlesTxt.alpha = .8;

			subtitlesTxt.cameras = [ camOther ];
		}

		if (secondOpponentStrums != null)
		{
			worldStrumLineNotes = new FlxTypedGroup<StrumNote>();
			add(worldStrumLineNotes);
		}

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if (ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

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

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * .89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll) healthBarBG.y = .11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("comic.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(0, timeBarBG.y + 55, FlxG.width - 800, "this person\nis cheating", 32);

		botplayTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();

		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;

		botplayTxt.updateHitbox();
		botplayTxt.screenCenter(X);

		botplayTxt.x -= 7.5;
		add(botplayTxt);

		if (ClientPrefs.downScroll) botplayTxt.y = timeBarBG.y - 118;
		if (worldStrumLineNotes != null)
		{
			worldStrumLineNotes.cameras = [camGame];
			worldNotes.cameras = [camGame];
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];

		notes.cameras = [camHUD];

		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];

		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];

		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];

		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];

		timeTxt.cameras = [camHUD];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			switch (curSong)
			{
				// case 'test': startDialogue(dialogueJson);
				case 'gastric-bypass': startVideo('animation_gastric_bypass');
				case 'roided': startVideo('animation_roided');

				case 'kleptomaniac': startVideo('animation_evil_bf');

				case 'cervix': startVideo('animation_cervix');
				case 'funny-duo': startVideo('animation_funny_duo');
				case 'intestinal-failure': startVideo('animation_intestinal_failure');

				default: startCountdown();
			}
			seenCutscene = true;
		} else { startCountdown(); }
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		#if (desktop && !neko)
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter());
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		super.create();
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		return value;
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		healthBar.updateBar();
	}

	// public function addCharacterToList(newCharacter:String, type:Int) {
	// 	switch(type) {
	// 		case 0:
	// 			if (!boyfriendMap.exists(newCharacter)) {
	// 				var newBoyfriend:Character = new Character(0, 0, newCharacter, true);

	// 				boyfriendMap.set(newCharacter, newBoyfriend);
	// 				boyfriendGroup.add(newBoyfriend);

	// 				startCharacterPos(newBoyfriend);
	// 			}

	// 		case 1:
	// 			if (!dadMap.exists(newCharacter)) {
	// 				var newDad:Character = new Character(0, 0, newCharacter);

	// 				dadMap.set(newCharacter, newDad);
	// 				dadGroup.add(newDad);

	// 				startCharacterPos(newDad, true);
	// 			}

	// 		case 2:
	// 			if (!gfMap.exists(newCharacter)) {
	// 				var newGf:Character = new Character(0, 0, newCharacter);
	// 				newGf.scrollFactor.set(.95, 0.95);

	// 				gfMap.set(newCharacter, newGf);
	// 				gfGroup.add(newGf);

	// 				startCharacterPos(newGf);
	// 			}
	// 	}
	// }

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{
			//IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(.95, 0.95);
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String, skipTransIn:Bool = false):Void {
		#if VIDEOS_ALLOWED
		var fileName:String = Paths.video(name);
		#if sys
		if (FileSystem.exists(fileName)) {
		#else
		if (OpenFlAssets.exists(fileName)) {
		#end
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);

			bg.scrollFactor.set();
			bg.cameras = [camHUD];

			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				switch (endingSong)
				{
					case true: cleanupEndSong(skipTransIn);
					default: startCountdown();
				}
			}
			return;
		} else { FlxG.log.warn('Couldnt find video file: ' + fileName); }
		#end
		switch (endingSong)
		{
			case true: cleanupEndSong(skipTransIn);
			default: startCountdown();
		}
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBox;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null) return;
		if (dialogueFile.dialogue.length > 0) {
			inCutscene = true;

			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');

			var doof:DialogueBox = new DialogueBox(dialogueFile, song);
			var finishCallback = endingSong ? endSong : startCountdown;

			doof.scrollFactor.set();
			doof.finishThing = function() {
				psychDialogue = null;
				finishCallback();
			}

			doof.nextDialogueThing = startNextDialogue;
			doof.cameras = [camHUD];

			add(doof);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong) { endSong(); } else { startCountdown(); }
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	public var countdownImage:FlxSprite;
	private function charDance(char:Character, beat:Int)
	{
		var curAnim:FlxAnimation = char.animation.curAnim;
		var speed:Int = (char.curCharacter.startsWith("gf") || char.danceIdle) ? gfSpeed : 2;

		if (curAnim != null && (beat % speed) == 0 && !char.stunned && !curAnim.name.startsWith("sing")) char.dance();
	}

	private function groupDance(chars:FlxSpriteGroup, beat:Int)
	{
		for (i in 0...chars.length)
		{
			var char:Character = cast(chars.members[i], Character);
			charDance(char, beat);
		}
	}
	private function stageDance(beat:Int)
	{
		if (beat % gfSpeed == 0)
		{
			for (i in 0...stageGroup.length)
			{
				var sprite:BGSprite = cast(stageGroup.members[i], BGSprite);
				sprite.dance(true);
			}
		}
	}

	private function bfDance()
	{
		var curAnim:FlxAnimation = boyfriend.animation.curAnim;
		if (curAnim != null)
		{
			var animName = curAnim.name;
			if (boyfriend.holdTimer > ((Conductor.stepCrochet / 1000) * boyfriend.singDuration) && (animName.startsWith("sing") && !animName.endsWith("miss"))) boyfriend.dance();
		}
	}

	function cleanupTween(?twn:FlxTween)
	{
		if (modchartTweens.contains(twn)) modchartTweens.remove(twn);
		//if (twn != null && twn.finished && twn.active)
		//{
		//	twn.active = false;
		//	twn.destroy();
		//}
	}
	function cleanupTimer(?tmr:FlxTimer)
	{
		if (modchartTimers.contains(tmr)) modchartTimers.remove(tmr);
		//if (tmr != null && tmr.finished && tmr.active)
		//{
		//	tmr.active = false;
		//	tmr.destroy();
		//}
	}

	public function startCountdown():Void
	{
		if (startedCountdown) return;
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		if (secondOpponentStrums != null) generateStaticArrows(2);

		startedCountdown = true;
		Conductor.songPosition = -Conductor.crochet * 5;

		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssetsSuffix = switch (curSong)
		{
			case 'tutorial': '-compressed';
			default: '';
		}
		introAssetsPrefix = switch (curSong)
		{
			case 'tutorial': 'compressed/';
			default: '';
		}

		introAssets.set('-compressed', ['compressed/ready', 'compressed/set', 'compressed/go']);
		introAssets.set('default', ['rady', 'set', 'kys']);

		var introAlts:Array<String> = introAssets.exists(introAssetsSuffix) ? introAssets.get(introAssetsSuffix) : introAssets.get('default');
		for (key in introAlts) CoolUtil.precacheAsset(Paths.image(key));

		countdownImage = new FlxSprite();

		countdownImage.antialiasing = ClientPrefs.globalAntialiasing;
		countdownImage.scrollFactor.set();

		countdownImage.alpha = 0;
		add(countdownImage);

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			notes.forEachAlive(function(note:Note)
			{
				note.copyAlpha = false;
				note.alpha = note.multAlpha;

				if (ClientPrefs.middleScroll && !note.mustPress) note.alpha *= .5;
			});

			var loopsLeft:Int = tmr.loopsLeft;
			var count = tmr.elapsedLoops - 2;

			groupDance(gfGroup, loopsLeft);
			groupDance(boyfriendGroup, loopsLeft);
			groupDance(dadGroup, loopsLeft);

			stageDance(loopsLeft);
			if (count >= 0 && count < introAlts.length)
			{
				countdownImage.loadGraphic(Paths.image(introAlts[count]));
				FlxTween.cancelTweensOf(countdownImage);

				countdownImage.updateHitbox();
				countdownImage.screenCenter();

				countdownImage.alpha = 1;
				modchartTweens.push(FlxTween.tween(countdownImage, { alpha: 0 }, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween)
					{
						if (loopsLeft <= 0)
						{
							remove(countdownImage);
							countdownImage.destroy();
							cleanupTimer(tmr);
						}
						cleanupTween(twn);
					}
				}));
			}
			FlxG.sound.play(Paths.sound('intro${loopsLeft <= 0 ? 'Go' : Std.string(loopsLeft)}$introAssetsSuffix'), .6);
		}, 4);
	}

	function startNextDialogue() {
		dialogueCount++;
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		previousFrameTime = FlxG.game.ticks;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;

		var curTime:Float = FlxG.sound.music.time;

		FlxG.sound.music.play(true, curTime);
		vocals.play(true, curTime);

		Conductor.songPosition = curTime;

		// FlxG.sound.music.time = curTime;
		// vocals.time = curTime;

		resyncVocals(true);
		Conductor.songPosition = FlxG.sound.music.time;

		if (paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if (curSong != 'tutorial') camZooming = true;

		super.update(FlxG.elapsed);
		stepHit();
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		modchartTweens.push(FlxTween.tween(timeBar, { alpha: 1 }, 0.5, { ease: FlxEase.circOut, onComplete: cleanupTween }));
		modchartTweens.push(FlxTween.tween(timeTxt, { alpha: 1 }, 0.5, { ease: FlxEase.circOut, onComplete: cleanupTween }));

		#if (desktop && !neko)
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter(), true, songLength);
		#end
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
		Conductor.changeBPM(SONG.bpm);

		curSong = Paths.formatToSongPath(SONG.song);
		vocals = new FlxSound();

		var instPath:String = Paths.inst(curSong);
		if (SONG.needsVoices)
		{
			var vocalsPath:String = Paths.voices(curSong);
			vocals.loadEmbedded(vocalsPath);

			CoolUtil.precacheRawSound(vocalsPath);
			trace('cache $vocalsPath');
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(instPath));

		CoolUtil.precacheRawSound(instPath);
		trace('cache $instPath');

		notes = new FlxTypedGroup<Note>();
		if (worldStrumLineNotes != null)
		{
			worldNotes = new FlxTypedGroup<Note>();
			add(worldNotes);
		}
		add(notes);

		var noteData:Array<SwagSection>;
		// NEW SHIT
		noteData = SONG.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		var file:String = Paths.json('$curSong/events');

		#if sys
		if (FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', curSong).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:Array<Dynamic> = [newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote), newEventNote[1], newEventNote[2], newEventNote[3]];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}
		if (SONG.events != null)
		{
			for (event in SONG.events) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:Array<Dynamic> = [newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote), newEventNote[1], newEventNote[2], newEventNote[3]];
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
				if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;

				var oldNote:Note = null;
				if (unspawnNotes.length > 0) oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if (floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1)
							{ //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1) eventNotes.sort(sortByTime); //No need to sort if there's a single one or none at all

		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch (event[1]) {
			case 'Popup': { CoolUtil.precacheSound('disconnect'); CoolUtil.precacheAsset(Paths.image('popup')); }
			case 'Vignette':
			{
				if (vignetteImage == null)
				{
					var imagePath:String = Paths.image('vignette');
					vignetteImage = new FlxSprite().loadGraphic(imagePath, false);

					vignetteImage.setGraphicSize(FlxG.width, FlxG.height);
					vignetteImage.updateHitbox();

					vignetteImage.screenCenter();
					vignetteImage.scrollFactor.set();

					vignetteImage.cameras = [ camOther ];
					vignetteImage.alpha = 0;

					CoolUtil.precacheAsset(imagePath);
					add(vignetteImage);
				}
			}
			case 'Extend Timer':
			{
				if (timerExtensions == null) { timerExtensions = new Array<Float>(); }

				timerExtensions.push(event[0]);
				maskedSongLength = timerExtensions[0];
			}

			case 'Change Character':
			{
				var newCharacter:String = event[3];
				var path:String = Paths.getPreloadPath('characters/$newCharacter.json');

				if (Assets.exists(path))
				{
					var json = Json.parse(Assets.getText(path));
					var image:String = Paths.image(json.image);

					if (Assets.exists(image)) CoolUtil.precacheAsset(image);
				}
				//addCharacterToList(newCharacter, charType);
			}
		}
		if (!eventPushedMap.exists(event[1])) eventPushedMap.set(event[1], true);
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		// switch(event[1]) {
		// 	case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
		// 		return 280; //Plays 280ms before the actual position
		// }
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var isWorldStrumLine:Bool = player > 1;

			var strumLinePushing:FlxTypedGroup<StrumNote> = isWorldStrumLine ? worldStrumLineNotes : strumLineNotes;
			var strumLineSprite:FlxSprite = isWorldStrumLine ? worldStrumLine : strumLine;

			var targetAlpha:Float = switch (isWorldStrumLine)
			{
				case true: .65;
				default: ClientPrefs.middleScroll ? .35 : 1;
			}

			var babyArrow:StrumNote = new StrumNote(isWorldStrumLine ? strumLineSprite.x : (ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X), strumLineSprite.y, i, isWorldStrumLine ? 0 : player);
			if (isStoryMode) { babyArrow.alpha = targetAlpha; }
			else
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				modchartTweens.push(FlxTween.tween(babyArrow, { y: babyArrow.y + 10, alpha: targetAlpha }, 1, { ease: FlxEase.circOut, startDelay: .5 + (.2 * i), onComplete: cleanupTween }));
			}

			switch (player)
			{
				case 1: playerStrums.add(babyArrow);
				case 2:
				{
					babyArrow.texture = 'Pink_Note_Assets';
					babyArrow.reloadNote();

					babyArrow.scrollFactor.set(1, 1);
					secondOpponentStrums.add(babyArrow);
				}

				default:
				{
					if (ClientPrefs.middleScroll)
					{
						babyArrow.x += 310;
						if (i > 1) babyArrow.x += FlxG.width / 2 + 25; //Up and Right
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
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished) startTimer.active = false;

			if (finishTimer != null && !finishTimer.finished) finishTimer.active = false;
			if (songSpeedTween != null) songSpeedTween.active = false;

			var chars:Array<Character> = [ boyfriend, gf, dad ];

			if (pinkSoldier != null) chars.push(pinkSoldier);
			for (i in 0...chars.length) {
				if (chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) tween.active = false;
			for (timer in modchartTimers) timer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong) resyncVocals(true);

			if (!startTimer.finished) startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = true;

			if (songSpeedTween != null) songSpeedTween.active = true;
			var chars:Array<Character> = [boyfriend, gf, dad];

			if (pinkSoldier != null) chars.push(pinkSoldier);
			for (i in 0...chars.length) {
				if (chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}

			for (tween in modchartTweens) tween.active = true;
			for (timer in modchartTimers) timer.active = true;

			paused = false;
			#if (desktop && !neko)
			DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter(), startTimer.finished, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		quickUpdatePresence();

		focused = true;
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		quickUpdatePresence('PAUSED - ', false);

		focused = false;
		super.onFocusLost();
	}

	function resyncVocals(?forceMusic:Bool = false):Void
	{
		if (finishTimer != null) return;

		var curTime:Float = FlxG.sound.music.time;
		var curVocals:Float = vocals.time;

		if (forceMusic || curVocals > curTime + vocalResyncTime || curVocals < curTime - vocalResyncTime)
		{
			// im like 90% sure this yields so i'm force restarting it and caching the current music time, then restarting it
			FlxG.sound.music.play(true);
			vocals.play(true);

			FlxG.sound.music.time = curTime;
			vocals.time = curTime;
		}
		Conductor.songPosition = curTime;
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/
		if (!inCutscene) {
			var curBar:Int = Std.int(curStep / 16);
			var curNote:SwagSection = SONG.notes[curBar];

			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);

			cancelCameraDelta(boyfriend);
			cancelCameraDelta(dad);

			if (pinkSoldier != null) cancelCameraDelta(pinkSoldier);
			var usePlayerDelta:Bool = curNote != null && curNote.mustHitSection;

			var point:FlxPoint = usePlayerDelta ? playerDelta : opponentDelta;
			var multiplier:Float = ClientPrefs.reducedMotion ? 0 : cameraOffset;

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

					if (secondX != 0 || secondY != 0) { followX += 250; followY -= 100; newZoom = stageData.defaultZoom + .2; }
				}
				defaultCamZoom = newZoom;
			}
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, followX, lerpVal), FlxMath.lerp(camFollowPos.y, followY, lerpVal));
		}

		super.update(elapsed);
		var ratingText:String = 'score: $songScore | horse cheeses: $songMisses | rating: $ratingName';

		if (ratingName != '?') ratingText += ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC'; //peeps wanted no integer rating
		scoreTxt.text = ratingText;

		if (botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			//}
			#if (desktop && !neko)
			DiscordClient.changePresence(detailsPausedText, getFormattedSong(), iconP2.getCharacter());
			#end
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		// var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		// iconP1.scale.set(mult, mult);
		// iconP1.updateHitbox();

		// var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		// iconP2.scale.set(mult, mult);
		// iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) / 100)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) / 100)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		health = Math.min(health, 2);

		iconP1.animation.curAnim.curFrame = healthBar.percent < losingPercent ? 1 : 0;
		iconP2.animation.curAnim.curFrame = healthBar.percent > (100 - losingPercent) ? 1 : 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;

			cancelMusicFadeTween();

			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		var elapsedMult:Float = FlxG.elapsed * 1000;
		var elapsedTicks:Int = FlxG.game.ticks;

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += elapsedMult;
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else
		{
			Conductor.songPosition += elapsedMult;
			if (!paused)
			{
				songTime += elapsedTicks - previousFrameTime;
				previousFrameTime = elapsedTicks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if (updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					var lengthUsing:Float = (maskedSongLength > 0) ? maskedSongLength : songLength;

					curTime = Math.max(curTime, 0);
					songPercent = (curTime / lengthUsing);

					var songCalc:Float = (lengthUsing - curTime);
					if (ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(Math.max(songCalc / 1000, 0));
					if (ClientPrefs.timeBarType != 'Song Name') timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}
		}

		if (camZooming)
		{
			var lerpSpeed:Float = CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1);
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, lerpSpeed);

			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, lerpSpeed);
			camGame.angle = FlxMath.lerp(0, camGame.angle, lerpSpeed);

			if (vignetteImage != null)
			{
				vignetteImage.setGraphicSize(FlxG.width, FlxG.height);
				vignetteImage.updateHitbox();

				vignetteImage.alpha = FlxMath.lerp(vignetteEnabled ? 1 : 0, vignetteImage.alpha, lerpSpeed);
			}
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(songSpeed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if (roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				if (dunceNote.noteType == 'Alt Animation' && !dunceNote.mustPress && worldNotes != null)
				{
					dunceNote.reloadNote('', 'Pink_Note_Assets');
					dunceNote.flipY = false;

					dunceNote.scrollFactor.set(1, 1);
					worldNotes.insert(0, dunceNote);
				}
				else
				{
					switch (dunceNote.noteType)
					{
						case 'horse cheese note':
						{
							if (horseImages == null)
							{
								var horsePath:String = 'images/horses/';

								var assetList:Array<String> = OpenFlAssets.list(IMAGE);
								var horseTemp:Array<String> = new Array<String>();

								for (asset in assetList)
								{
									if (asset.contains(horsePath))
									{
										var path:String = Paths.getPath(asset.substring(asset.indexOf(horsePath)), IMAGE);

										CoolUtil.precacheAsset(path);
										horseTemp.push(path);
									}
								}
								horseImages = horseTemp;
							}
						}
					}
					notes.insert(0, dunceNote);
				}

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strums:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : opponentStrums;
				var strumArrow:StrumNote = strums.members[daNote.noteData];

				var strumAngle:Float = strumArrow.angle + daNote.offsetAngle;
				var strumAlpha:Float = strumArrow.alpha * daNote.multAlpha;

				var strumX:Float = strumArrow.x + daNote.offsetX;
				var strumY:Float = strumArrow.y + daNote.offsetY;

				var center:Float = strumY + Note.swagWidth / 2;

				if (daNote.copyAngle) daNote.angle = strumAngle;
				if (daNote.copyAlpha) daNote.alpha = strumAlpha;

				if (daNote.copyX) daNote.x = strumX;
				if (daNote.copyY) {
					if (ClientPrefs.downScroll) {
						daNote.y = (strumY + .45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote && !ClientPrefs.keSustains) {
							//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;

								daNote.y -= 19;
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

							if (daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
						}
					} else {
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if (!ClientPrefs.keSustains)
						{
							if (daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.isSustainNote
									&& daNote.y + daNote.offset.y * daNote.scale.y <= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNoteHit(daNote);
				if (daNote.mustPress && cpuControlled) {
					if (daNote.isSustainNote) {
						if (daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (.45 * songSpeed));

				var doKill:Bool = daNote.y < -daNote.height;

				if (ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;
				if (ClientPrefs.keSustains && daNote.isSustainNote && daNote.wasGoodHit) doKill = true;

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
			if (worldNotes != null)
			{
				worldNotes.forEachAlive(function(daNote:Note)
				{
					var strumArrow:StrumNote = secondOpponentStrums.members[daNote.noteData];

					var strumAngle:Float = strumArrow.angle + daNote.offsetAngle;
					var strumAlpha:Float = strumArrow.alpha * daNote.multAlpha;

					var strumX:Float = strumArrow.x + daNote.offsetX;
					var strumY:Float = strumArrow.y + daNote.offsetY;

					var center:Float = strumY + Note.swagWidth / 2;

					if (daNote.copyAngle) daNote.angle = strumAngle;
					if (daNote.copyAlpha) daNote.alpha = strumAlpha;

					if (daNote.copyX) daNote.x = strumX;
					if (daNote.copyY) {
						daNote.y = (strumY - .45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (!ClientPrefs.keSustains)
						{
							if (!daNote.ignoreNote)
							{
								if (daNote.isSustainNote
									&& daNote.y + daNote.offset.y * daNote.scale.y <= center
									&& (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}
					}

					if (daNote.wasGoodHit && !daNote.ignoreNote) opponentNoteHit(daNote);
					var doKill:Bool = daNote.y < -daNote.height;

					if (ClientPrefs.keSustains && daNote.isSustainNote && daNote.wasGoodHit) doKill = true;
					if (doKill)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
			checkEventNote();
		}

		if (!inCutscene) {
			if (!cpuControlled) { keyShit(); }
			else { bfDance(); }
		}

		#if debug
		if (!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if (daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		CustomFadeTransition.nextCamera = camOther;
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if (desktop && !neko)
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			boyfriend.stunned = true;
			deathCounter++;

			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			persistentUpdate = false;
			persistentDraw = false;

			for (tween in modchartTweens) tween.active = true;
			for (timer in modchartTimers) timer.active = true;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

			// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if (desktop && !neko)
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence('Game Over - $detailsText', getFormattedSong(false), iconP2.getCharacter());
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	public function checkEventNote() {
		while (eventNotes.length > 0)
		{
			var event:Array<Dynamic> = eventNotes[0];
			var leStrumTime:Float = event[0];

			if (Conductor.songPosition < leStrumTime) break;

			var value1:String = '';
			var value2:String = '';

			if (event[2] != null) value1 = event[2];
			if (event[3] != null) value2 = event[3];

			triggerEventNote(event[1], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	function tweenMask(temp:FlxSprite, value:Float) { maskedSongLength = value; }
	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch (eventName) {
			case 'Hey!':
			{
				var time:Float = Std.parseFloat(value2);
				var value:Int = switch(value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend' | '1': 1;
					case 'bf' | 'boyfriend' | '0': 0;

					default: 2;
				};

				if (Math.isNaN(time) || time <= 0) time = .6;
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
				if (Math.isNaN(value)) value = 1;
				gfSpeed = value;
			}
			case 'Add Camera Zoom':
			{
				if (ClientPrefs.camZooms)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);

					if (Math.isNaN(camZoom)) camZoom = .015;
					if (Math.isNaN(hudZoom)) hudZoom = .03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}
			}
			case 'Popup':
			{
				if (FlxG.random.bool())
				{
					var popup:FlxSprite = new FlxSprite().loadGraphic(Paths.image('popup'));

					var offsetY:Float = FlxG.random.float(-1, 1);
					var offsetX:Float = FlxG.random.float(-1, 1);

					popup.cameras = [ camOther ];
					popup.scale.set(.8, .8);

					popup.updateHitbox();
					popup.screenCenter();

					popup.offset.set(offsetX, offsetY);

					popup.scrollFactor.set();
					popup.alpha = .7;

					modchartTweens.push(FlxTween.tween(popup, { alpha: 1, "scale.x": 1, "scale.y": 1 }, 1 / 4, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
						modchartTimers.push(new FlxTimer().start(4, function(tmr:FlxTimer) {
							modchartTweens.push(FlxTween.tween(popup, { alpha: 0, "scale.x": .8, "scale.y": .8 }, 1 / 4, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) { remove(popup); popup.destroy(); cleanupTween(twn); }}));
							cleanupTimer(tmr);
						}));
						cleanupTween(twn);
					}, onUpdate: function(twn:FlxTween) { popup.updateHitbox(); popup.screenCenter(); popup.offset.set(offsetX, offsetY); }} ));

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

					FlxTween.cancelTweensOf(timeTxt);
					modchartTweens.push(FlxTween.num(maskedSongLength, (next != null && next > 0) ? next : songLength, Conductor.crochet / 1000, { ease: FlxEase.quintIn, onComplete: cleanupTween }, tweenMask.bind(timeTxt)));
				}
			}
			case 'Subtitles':
			{
				if (subtitlesTxt != null && ClientPrefs.subtitles)
				{
					var text:String = value1.trim();
					if (text.length > 0)
					{
						var char:Character = switch (value2.toLowerCase().trim()) {
							case 'gf' | 'girlfriend': gf;
							case 'dad' | 'opponent': dad;

							default: boyfriend;
						};
						subtitlesTxt.text = text;

						subtitlesTxt.updateHitbox();
						subtitlesTxt.screenCenter();

						var subtitlesY:Float = (healthBar.height + scoreTxt.height + subtitlesTxt.borderSize) * 2;
						var subtitlesSize:Float = subtitlesTxt.size;

						subtitlesTxt.y = switch (ClientPrefs.downScroll)
						{
							default: FlxG.height - subtitlesSize - subtitlesY - subtitlesTxt.height;
							case true: subtitlesY + (subtitlesSize * 1.5);
						};

						subtitlesTxt.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
						subtitlesTxt.visible = true;

						add(subtitlesTxt);
					}
					else { subtitlesTxt.visible = false; remove(subtitlesTxt); }
				}
			}

			case 'Set Zoom Type':
			{
				var value:Int = Std.parseInt(value1.trim());
				camZoomType = Math.isNaN(value) ? 0 : Std.int(CoolUtil.boundTo(value, 0, camZoomTypes.length - 1));
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

				if (color.length > 1) { if (!color.startsWith('0x')) color = '0xFF$color'; }
				else { color = "0xFFFFFFFF"; }

				if (ClientPrefs.flashing) camOther.flash(Std.parseInt(color), Math.isNaN(duration) ? 1 : duration, null, true);
			}
			case 'Change Character Visibility':
			{
				var visibility:String = value2.toLowerCase();
				var char:Character = switch (value1.toLowerCase().trim()) {
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
					if (sound != null && Std.isOfType(sound, FlxSound)) sound.play(true);
				}
				catch (e:Dynamic) { trace('Unknown sound tried to be played - $e'); }
			}
			case 'Play Animation':
			{
				//trace('Anim to play: ' + value1);
				var char:Character = switch (value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend': boyfriend;
					case 'gf' | 'girlfriend': gf;

					default:
					{
						var val2:Int = Std.parseInt(value2);

						if (Math.isNaN(val2)) val2 = 0;
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

				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;

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
				var char:Character = switch (value1.toLowerCase())
				{
					case 'boyfriend' | 'bf': boyfriend;
					case 'gf' | 'girlfriend': gf;

					default:
					{
						var val:Int = Std.parseInt(value1);

						if (Math.isNaN(val)) val = 0;
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

				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;

				gameShakeAmount = val1;
				hudShakeAmount = val2;

				doSustainShake();
			}
			case 'Screen Shake':
			{
				if (!ClientPrefs.reducedMotion)
				{
					var valuesArray:Array<String> = [value1, value2];
					var targetsArray:Array<FlxCamera> = [camGame, camHUD];

					for (i in 0...targetsArray.length) {
						var split:Array<String> = valuesArray[i].split(',');

						var intensity:Float = 0;
						var duration:Float = 0;

						if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
						if (split[0] != null) duration = Std.parseFloat(split[0].trim());

						if (Math.isNaN(intensity)) intensity = 0;
						if (Math.isNaN(duration)) duration = 0;

						if (duration > 0 && intensity != 0) targetsArray[i].shake(intensity, duration);
					}
				}
			}

			case 'Change Character':
			{
				var charType:Int = switch (value1)
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
								if (!dad.curCharacter.startsWith('gf')) { characterPositioning.setPosition(DAD_X, DAD_Y); if (wasGf) gf.visible = true; } else { gf.visible = false; characterPositioning.setPosition(GF_X, GF_Y); }
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

				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
				if (val2 <= 0) { songSpeed = newValue; }
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
							cleanupTween(twn);
						}
					});
				}
			}
		}
	}

	function moveCameraSection(?id:Int = 0):Void {
		if (SONG.notes[id] == null) return;
		if (SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
			return;
		}
		moveCamera(!SONG.notes[id].mustHitSection);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (curSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
						cleanupTween(twn);
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (curSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
					cleanupTween(twn);
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();

		if (ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
				cleanupTimer(tmr);
			});
		}
	}

	function canZoomCamera():Bool { return camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms; }
	private function cleanupEndSong(skipTransIn:Bool = false)
	{
		if (!transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					TitleState.playTitleMusic();
					cancelMusicFadeTween();

					CustomFadeTransition.nextCamera = if (FlxTransitionableState.skipNextTransIn) camOther else null;
					MusicBeatState.switchState(new StoryMenuState());

					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
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
				CustomFadeTransition.nextCamera = camOther;
				if (FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}

				MusicBeatState.switchState(new FreeplayState());
				TitleState.playTitleMusic();

				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if (!startingSong) {
			notes.forEach(function(daNote:Note) { if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= .05 * healthLoss; });

			for (daNote in unspawnNotes) { if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= .05 * healthLoss; }
			if (doDeathCheck()) return;
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

		switch (curSong)
		{
			case 'banana': startVideo('minion_fucking_dies', true);
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

	public function KillNotes() {
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
	public var totalNotesHit:Float = .0;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * .35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);
		switch (daRating)
		{
			case "horsedog": shits++; // shit
			case "bad": // bad
			{
				totalNotesHit += .5;
				bads++;
			}
			case "goog": // good
			{
				totalNotesHit += .75;
				goods++;
			}
			case "funny": // sick
			{
				totalNotesHit += 1;
				sicks++;
			}
		}


		if (daRating == "funny" && !note.noteSplashDisabled) spawnNoteSplashOnNote(note);
		if (!practiceMode && !cpuControlled)
		{
			songScore += score;

			songHits++;
			totalPlayed++;

			RecalculateRating();
			if (ClientPrefs.scoreZoom)
			{
				if (scoreTxtTween != null) scoreTxtTween.cancel();

				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;

				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
						cleanupTween(twn);
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = "funny";
			else if (combo > 12)
				daRating = "goog"
			else if (combo > 4)
				daRating = "bad";
		 */

		rating.loadGraphic(Paths.image(introAssetsPrefix + daRating + introAssetsSuffix));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('${introAssetsPrefix}combo$introAssetsSuffix'));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		rating.setGraphicSize(Std.int(rating.width * .7));
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * .7));
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];
		if (combo >= 1000) seperatedScore.push(Math.floor(combo / 1000) % 10);

		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);

		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('${introAssetsPrefix}num${Std.int(i)}$introAssetsSuffix'));

			numScore.cameras = [camHUD];
			numScore.screenCenter();

			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			numScore.antialiasing = ClientPrefs.globalAntialiasing;

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0) insert(members.indexOf(strumLineNotes), numScore);
			modchartTweens.push(FlxTween.tween(numScore, { alpha: 0 }, 0.2, {
				onComplete: function(tween:FlxTween) { numScore.destroy(); cleanupTween(tween); },
				startDelay: Conductor.crochet / 500
			}));
			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		modchartTweens.push(FlxTween.tween(rating, { alpha: 0 }, 0.2, { startDelay: Conductor.crochet / 1000, onComplete: cleanupTween }));
		modchartTweens.push(FlxTween.tween(comboSpr, { alpha: 0 }, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
				cleanupTween(tween);
			},
			startDelay: Conductor.crochet / 1000
		}));
	}

	public function getFormattedSong(?getRating:Bool = true)
	{
		#if (desktop && !neko)
		var start = '${SONG.song} ($storyDifficultyText)';
		if (getRating)
		{
			var floored:String = ratingName == '?' ? '?' : '$ratingName (${Highscore.floorDecimal(ratingPercent * 100, 2)}%)';
			start = 'score: $songScore | horse cheeses: $songMisses | rating: $floored';
		}
		return start;
		#end
	}
	private function quickUpdatePresence(?startString:String = "", ?hasLength:Bool = true)
	{
		#if (desktop && !neko)
		if (health > 0 && !paused) DiscordClient.changePresence(detailsText, '$startString${getFormattedSong()}', iconP2.getCharacter(), hasLength && Conductor.songPosition > 0, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
		#end
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if (daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else { if (canMiss) noteMissPress(key); }
				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		//trace('pressed: ' + controlArray);
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
		//trace('released: ' + controlArray);
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
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
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
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});
			bfDance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by horse cheese notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if (!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if (daNote.gfNote) {
			char = gf;
		}

		if (char.hasMissAnimations)
		{
			var daAlt = '';
			if (daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}
		quickUpdatePresence();
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= .05 * healthLoss;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if (!practiceMode) songScore -= 10;
			if (!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if (boyfriend.hasMissAnimations) boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			vocals.volume = 0;

			quickUpdatePresence();
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		var isAlternative:Bool = false;
		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = .6;
		} else if (!note.noAnimation) {
			var curSection:Int = Math.floor(curStep / 16);
			var altAnim:String = "";

			var char:Character = dad;
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					switch (curSong)
					{
						case 'squidgames':
						{
							if (pinkSoldier != null)
							{
								char = pinkSoldier;
								isAlternative = true;
							}
						}
						default: altAnim = '-alt';
					}
				}
			}

			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;

			if (note.gfNote) char = gf;
			if (!char.specialAnim)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices) vocals.volume = 1;
		var time:Float = .15;

		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) time *= 2;
		var difficultyClamp = Math.max(storyDifficulty, 1);

		var fixedDrain:Float = healthDrain * (difficultyClamp / (Math.PI / 2));
		var fixedDrainCap:Float = healthDrainCap / difficultyClamp;
		// [ divide by, difficulty minimum ]
		var drainDiv:Dynamic = switch (curSong)
		{
			case 'kleptomaniac': [ 4, 0 ];
			default: null;
		}
		if (drainDiv != null && (drainDiv[2] == null || drainDiv[1] <= storyDifficulty) && !note.isSustainNote)
		{
			var divider:Float = drainDiv[0];
			if (health > fixedDrainCap) health = Math.max(health - (fixedDrain / divider), fixedDrainCap);
		}

		var leData:Int = CoolUtil.wrapNoteData(note.noteData);
		var camDelta:FlxPoint = getCameraDelta(leData);

		if (!isAlternative) { opponentDelta = camDelta; }
		else { if (secondOpponentDelta != null) secondOpponentDelta = camDelta; }

		StrumPlayAnim(isAlternative ? 2 : 1, leData, time);

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

			var isSus:Bool = note.isSustainNote;
			var leData:Int = CoolUtil.wrapNoteData(note.noteData);

			playerDelta = getCameraDelta(leData);
			if (note.hitCausesMiss) {
				noteMiss(note);

				if (!note.noteSplashDisabled && !isSus) spawnNoteSplashOnNote(note);
				switch (note.noteType) {
					case 'horse cheese note': // horse cheese note
					{
						if (dad.animOffsets.exists('horsecheese'))
						{
							dad.playAnim('horsecheese', true);
							dad.specialAnim = true;
						}
						modchartTimers.push(new FlxTimer().start(1 / 20, function(tmr:FlxTimer) {
							if (horseImages != null)
							{
								var roll:String = FlxG.random.getObject(horseImages);
								var width = FlxG.width * FlxG.random.float(.4, .8);

								var horsey:FlxSprite = new FlxSprite().loadGraphic(roll);
								FlxG.sound.play(Paths.sound("ANGRY"), 1);

								horsey.setGraphicSize(Std.int(width), Std.int(width * FlxG.random.float(.1, 2)));
								horsey.cameras = [ camOther ];

								horsey.updateHitbox();
								horsey.screenCenter();

								horsey.y += (FlxG.height / 2) * FlxG.random.float(-1, 1);
								horsey.x += (FlxG.width / 2) * FlxG.random.float(-1, 1);

								horsey.flipY = FlxG.random.bool(20);
								horsey.flipX = FlxG.random.bool();

								horsey.alpha = FlxG.random.float(.9);
								add(horsey);

								modchartTweens.push(FlxTween.tween(horsey, { alpha: 0 }, FlxG.random.float(5, 20), { ease: FlxEase.sineInOut, onComplete: function(twn:FlxTween) {
									remove(horsey);
									horsey.destroy();
									cleanupTween(twn);
								} }));
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
				if (!isSus)
				{
					note.kill();

					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!isSus)
			{
				combo = Std.int(Math.min(combo + 1, 9999));
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;
			if (!note.noAnimation) {
				var daAlt:String = note.noteType == "Alt Animation" ? "-alt" : "";

				var animToPlay:String = singAnimations[leData];
				var charNote:Character = note.gfNote ? gf : boyfriend;

				if (!charNote.specialAnim)
				{
					charNote.playAnim('$animToPlay$daAlt', true);
					charNote.holdTimer = 0;
				}
				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);

						boyfriend.specialAnim = true;
						boyfriend.heyTimer = .6;
					}
					if (gf.animOffsets.exists('cheer'))
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
				if (isSus && !note.animation.curAnim.name.endsWith('end')) time *= 2;
				StrumPlayAnim(0, leData % 4, time);
			} else { playerStrums.forEach(function(spr:StrumNote) { if (leData == spr.ID) spr.playAnim('confirm', true); }); }

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!isSus)
			{
				note.kill();

				notes.remove(note, true);
				note.destroy();
			}
		}
		quickUpdatePresence();
	}

	function cancelCameraDelta(char:Character)
	{
		if (!char.animation.name.startsWith('sing'))
		{
			var deltaCancel:FlxPoint = switch (char.isPlayer)
			{
				case true: playerDelta;
				default: char == pinkSoldier ? secondOpponentDelta : opponentDelta;
			};
			deltaCancel.set();
		}
	}
	function getCameraDelta(leData:Int):FlxPoint
	{
		return new FlxPoint(switch(leData)
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
	function spawnNoteSplashOnNote(note:Note) {
		if (ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;

		if (note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);

		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if (FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}
	function doSustainShake()
	{
		if (!ClientPrefs.reducedMotion)
		{
			var stepCrochet:Float = Conductor.stepCrochet / 1000;

			if (gameShakeAmount > 0) camGame.shake(gameShakeAmount, stepCrochet);
			if (hudShakeAmount > 0) camHUD.shake(hudShakeAmount, stepCrochet);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if (FlxG.sound.music.time > Conductor.songPosition + vocalResyncTime || FlxG.sound.music.time < Conductor.songPosition - vocalResyncTime) resyncVocals();
		if (curStep == lastStepHit) return;

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		if (canZoomCamera() && !zoomFunction[0]) zoomFunction[1]();

		doSustainShake();
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	function getStretchValue(value:Bool):Float { return value ? -1 : .5; }

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) return;
		if (generatedMusic)
		{
			if (worldNotes != null) worldNotes.sort(FlxSort.byY, FlxSort.DESCENDING);
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var curBar:Int = Std.int(curStep / 16);
		var curNote:SwagSection = SONG.notes[curBar];

		if (curNote != null && curNote.changeBPM) Conductor.changeBPM(curNote.bpm);
		if (generatedMusic && curNote != null && !endingSong && !isCameraOnForcedPos) moveCameraSection(curBar);

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];

		if (canZoomCamera() && zoomFunction[0]) zoomFunction[1]();
		if (curBeat % gfSpeed == 0)
		{
			var stretchBool:Bool = (curBeat % (gfSpeed * 2)) == 0;

			var stretchValueOpponent:Float = getStretchValue(!stretchBool);
			var stretchValuePlayer:Float = getStretchValue(stretchBool);

			var angleValue:Float = 15 * FlxMath.signOf(stretchValuePlayer);
			var scaleValue:Float = .4;

			var scaleDefault:Float = 1.1;
			var crochetDiv:Float = 1300;

			iconP1.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValuePlayer));
			iconP2.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValueOpponent));

			modchartTweens.push(FlxTween.angle(iconP1, -angleValue, 0, Conductor.crochet / (crochetDiv * gfSpeed), { ease: FlxEase.quadOut, onComplete: cleanupTween }));
			modchartTweens.push(FlxTween.angle(iconP2, angleValue, 0, Conductor.crochet / (crochetDiv * gfSpeed), { ease: FlxEase.quadOut, onComplete: cleanupTween }));

			modchartTweens.push(FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / (crochetDiv * gfSpeed), { ease: FlxEase.quadOut, onComplete: cleanupTween }));
			modchartTweens.push(FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / (crochetDiv * gfSpeed), { ease: FlxEase.quadOut, onComplete: cleanupTween }));

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		// iconP1.scale.set(1.2, 1.2);
		// iconP2.scale.set(1.2, 1.2);

		// iconP1.updateHitbox();
		// iconP2.updateHitbox();

		groupDance(gfGroup, curBeat);
		groupDance(boyfriendGroup, curBeat);
		groupDance(dadGroup, curBeat);

		stageDance(curBeat);

		//charDance(gf, curBeat);
		//charDance(boyfriend, curBeat);
		//charDance(dad, curBeat);

		// if (pinkSoldier != null) charDance(pinkSoldier, curBeat);
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
					for (strumNote in opponentStrums.members) modchartTweens.push(FlxTween.tween(strumNote, { alpha: 0 }, Conductor.crochet / 500, { ease: FlxEase.cubeIn, onComplete: cleanupTween }));
				}
			}
		}
		lastBeatHit = curBeat;
	}

	function StrumPlayAnim(player:Int, id:Int, time:Float) {
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
	public function RecalculateRating() {
		if (totalPlayed < 1) ratingName = '?';
		else
		{
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

			// Rating Name
			if (ratingPercent >= 1)
			{
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length-1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingName = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		// Rating FC
		ratingFC = "";

		if (sicks > 0) ratingFC = "shitfartcombo";
		if (goods > 0) ratingFC = "googulus combo";

		if (bads > 0 || shits > 0) ratingFC = "full combo";

		if (songMisses > 0 && songMisses < 10) ratingFC = "shit fart";
		else if (songMisses >= 10) ratingFC = "kill yourself immediatly";
	}
}