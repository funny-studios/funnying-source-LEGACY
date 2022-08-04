package;

import Discord.DiscordClient;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import flixel.FlxCamera;
import flixel.FlxG;

class AchievementsState extends MusicBeatState
{
	public static var kleptomaniacAllowedMisses:Int = 50;
	public static var achievementsUnlocked:Map<String, Bool> = [];
	// Icon name
	// Achievement name
	// Achievement description
	// (optional) Secret
	public static var achievements:Array<Array<Dynamic>> = [
		[ 'week1', 'Gastrointestinal Disease', 'FC the first week on ${CoolUtil.defaultDifficulties[1]} or ${CoolUtil.defaultDifficulties[2]} (get less than $kleptomaniacAllowedMisses misses on Kleptomaniac).' ],
		[ 'week2', 'Funny Homosexuals', 'FC the second week.' ],

		[ 'WEED', '420', 'Nice.', true ]
	];
	private static var curSelected:Int = -1;

	private static var downscaleLength:Int = 18;
	// hardcoded scale value just incase
	private static var iconScale:Int = 128;

	private static var spacing:Float = 70;
	private static var padding:Float = 20;

	var achievementList:FlxTypedGroup<Alphabet>;
	var iconList:FlxTypedGroup<AttachedSprite>;

	var descriptionGroup:FlxSpriteGroup;
	var descriptionOffset:Float = 0;

	var descriptionBox:FlxSprite;
	var descriptionText:FlxText;

	var quitting:Bool = false;
	var moveTween:FlxTween;

	var holdTime:Float = 0;
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');

		achievementList = new FlxTypedGroup<Alphabet>();
		iconList = new FlxTypedGroup<AttachedSprite>();

		descriptionGroup = new FlxSpriteGroup();

		descriptionText = new FlxText(0, 0, FlxG.width * .8).setFormat(Paths.font('comic.ttf'), 32, FlxColor.WHITE, CENTER);
		descriptionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);

		descriptionText.antialiasing = globalAntialiasing;
		descriptionBox.antialiasing = false;

		descriptionText.bold = true;
		descriptionBox.alpha = .6;

		descriptionGroup.add(descriptionBox);
		descriptionGroup.add(descriptionText);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG'));

		bg.antialiasing = globalAntialiasing;
		bg.screenCenter();

		for (i in 0...achievements.length)
		{
			var achievement:Array<Dynamic> = achievements[i];

			var title:String = achievement[1];
			var name:String = achievement[0];

			var tooLong:Float = CoolUtil.boundTo(downscaleLength / Math.max(title.length, downscaleLength), .1, 1);
			var unlocked:Bool = isAchievementUnlocked(name);

			var alphabet:Alphabet = new Alphabet(0, spacing * i, unlocked ? title : '?', true, false, 0, tooLong);
			var icon:AttachedSprite = new AttachedSprite('achievements/${unlocked ? name : 'locked'}');

			alphabet.ID = i;
			alphabet.isMenuItem = true;

			alphabet.screenCenter(X);
			alphabet.yAdd -= spacing;

			alphabet.forceX = alphabet.x;
			alphabet.targetY = i;

			icon.antialiasing = false;

			icon.setGraphicSize(iconScale);
			icon.updateHitbox();

			icon.yAdd = (alphabet.height - icon.height) / 2;
			icon.xAdd = -(icon.width + padding);

			icon.sprTracker = alphabet;

			achievementList.add(alphabet);
			iconList.add(icon);

			if (curSelected <= -1) curSelected = i;
		}
		add(bg);

		add(achievementList);
		add(iconList);

		add(descriptionGroup);
		changeSelection();

		super.create();
	}
	override function update(elapsed:Float)
	{
		if (!quitting)
		{
			if (controls.BACK)
			{
				persistentUpdate = false;
				quitting = true;

				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			var delta:Int = CoolUtil.boolToInt(controls.UI_DOWN_P) - CoolUtil.boolToInt(controls.UI_UP_P);
			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

			if (delta != 0)
			{
				changeSelection(delta * shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - .5) * 10);
				holdTime += elapsed;

				var checkNewHold:Int = Math.floor((holdTime - .5) * 10);
				var holdDiff:Int = checkNewHold - checkLastHold;

				if (holdTime > .5 && holdDiff > 0)
				{
					var holdDelta:Int = CoolUtil.boolToInt(controls.UI_DOWN) - CoolUtil.boolToInt(controls.UI_UP);
					if (holdDelta != 0) changeSelection(holdDiff * shiftMult * holdDelta);
				}
			}
		}
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
		achievementList.forEachAlive(function(achievement:Alphabet) {
			if (achievement.targetY == 0)
			{
				var lastX:Float = achievement.x;

				achievement.screenCenter(X);
				achievement.x = FlxMath.lerp(lastX, achievement.x + (iconScale / 2), lerpVal);

				achievement.forceX = achievement.x;
				if (controls.ACCEPT)
				{
					#if debug
					add(new Achievement(achievements[achievement.ID][0], null));
					#end
					FlxG.sound.play(Paths.sound('cancelMenu'), .5);
				}
			}
			else
			{
				achievement.x = FlxMath.lerp(achievement.x, 300 - (50 * Math.abs(achievement.targetY)), lerpVal);
				achievement.forceX = achievement.x;
			}
		});

		repositionBox();
		super.update(elapsed);
	}
	private function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, achievements.length);
		achievementList.forEachAlive(function(achievement:Alphabet) {
			var id:Int = achievement.ID;
			achievement.targetY = id - curSelected;
			if (achievement.targetY == 0)
			{
				var index:Array<Dynamic> = achievements[id];
				if (index != null)
				{
					descriptionText.text = (!index[3] || isAchievementUnlocked(index[0])) ? index[2] : '?';
					repositionBox();
				}

				achievement.alpha = 1;
				return;
			}
			achievement.alpha = .6;
		});
		FlxG.sound.play(Paths.sound('scrollMenu'), .4);
		if (moveTween != null)
		{
			moveTween.cancel();
			moveTween.destroy();

			moveTween = null;
		}
		moveTween = FlxTween.num(0, 1, .25, { ease: FlxEase.quartOut, onUpdate: function(twn:FlxTween) { descriptionOffset = 10 * (1 - twn.scale); }, onComplete: function(twn:FlxTween) {
			descriptionOffset = 0;

			twn.destroy();
			moveTween = null;
		} });
	}

	public static function isAchievementUnlocked(achievement:String):Bool { return #if debug true #else achievementsUnlocked.exists(achievement) && achievementsUnlocked.get(achievement) #end; }
	public static function getAchievementIndex(achievement:String):Array<Dynamic> { for (index in achievements) { if (index[0] == achievement) return index; } return null; }

	public static function unlockAchievement(achievement:String)
	{
		if (isAchievementUnlocked(achievement)) return;
		achievementsUnlocked.set(achievement, true);

		FlxG.save.data.achievementsUnlocked = achievementsUnlocked;
		FlxG.save.flush();
	}
	private function repositionBox():Void
	{
		descriptionText.updateHitbox();
		descriptionBox.setGraphicSize(Std.int(descriptionText.width + padding), Std.int(descriptionText.height + padding + 5));

		descriptionBox.updateHitbox();

		descriptionText.screenCenter(X);
		descriptionBox.screenCenter(X);

		descriptionBox.y = FlxG.height - descriptionBox.height - descriptionOffset;
		descriptionText.y = (descriptionBox.y + descriptionBox.height) - descriptionText.height - descriptionOffset - (padding / 2);
	}
}
class Achievement extends FlxSpriteGroup
{
	private static var bgColorNew:FlxColor = FlxColor.fromRGB(0, 0, 0, 200);

	inline public static var defaultSound:String = 'achievementUnlocked';
	inline public static var defaultVolume:Float = .5;

	private static var bgHeight:Int = 130;
	private static var bgWidth:Int = 400;

	private static var nameSize:Int = 24;
	private static var textSize:Int = 18;
	private static var iconSize:Int = 64;

	public static var padding:Float = 10;
	private static var outline:Int = 4;

	private static function cleanupTween(twn:FlxTween):Void { twn.destroy(); }
	private static function cleanupTimer(tmr:FlxTimer):Void { tmr.destroy(); }

	public var onFinish(default, set):Void->Void = null;
	public var finished(default, set):Bool = false;

	public var bg:FlxSprite;
	private function set_onFinish(finish:Void->Void):Void->Void
	{
		if (finished && finish != null) finish();
		return this.onFinish = finish;
	}
	private function set_finished(value:Bool):Bool
	{
		if (value && onFinish != null) onFinish();
		return this.finished = value;
	}

	public function new(achievement:String, ?camera:FlxCamera, fake = false, ?sound:String, ?library:String, ?volume:Float = defaultVolume, yOffset:Float = 0)
	{
		super();
		#if !debug
		if (!fake)
		{
			if (AchievementsState.isAchievementUnlocked(achievement))
			{
				finished = true;
				return destroy(); // check if this crashes or not so i can fix a memory leak !!
			}
			AchievementsState.unlockAchievement(achievement);
		}
		#end
		if (sound == null && library == null)
		{
			sound = switch (achievement)
			{
				case 'WEED': 'smoke_weed';
				default: defaultSound;
			}
		}

		var index:Array<Dynamic> = AchievementsState.getAchievementIndex(achievement);
		if (index == null)
		{
			finished = true;
			return destroy();
		}

		var outlineDouble:Float = outline * 2;
		var outlineHalf:Float = outline / 2;

		var inlinePosition:Float = outlineHalf + outline;
		var borderPosition:Float = padding + outlineHalf;

		var icon:FlxSprite = new FlxSprite(padding + inlinePosition, padding + inlinePosition).loadGraphic(Paths.image('achievements/$achievement'));

		icon.setGraphicSize(iconSize, iconSize);
		icon.updateHitbox();

		var iconOutline:FlxSprite = new FlxSprite(borderPosition, borderPosition).makeGraphic(Std.int(iconSize + outlineDouble), Std.int(iconSize + outlineDouble), FlxColor.BLACK);

		var name:FlxText = new FlxText(icon.x + padding + iconSize + outlineHalf, icon.y + (nameSize / 2), bgWidth - ((padding * 2) + iconSize + outline), index[1]).setFormat(Paths.font('comic.ttf'), nameSize, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		var description:FlxText = new FlxText(padding, iconOutline.y + iconOutline.height + outline, bgWidth - (padding * 2), index[2]).setFormat(Paths.font('comic.ttf'), textSize, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

		bg = new FlxSprite().makeGraphic(bgWidth, Std.int(bgHeight + description.height - (textSize * 2)), FlxColor.WHITE);

		description.bold = true;
		name.bold = true;

		description.antialiasing = false;
		iconOutline.antialiasing = false;
		icon.antialiasing = false;
		name.antialiasing = false;
		bg.antialiasing = false;
		// poop
		bg.cameras = icon.cameras = name.cameras = description.cameras = iconOutline.cameras = cameras = [ camera != null ? camera : FlxG.camera ];
		bg.color = FlxColor.GREEN;

		alpha = .5;

		add(bg);
		add(description);

		add(iconOutline);
		add(icon);

		add(name);
		setPosition(FlxG.width - bg.width - padding, -bg.height);

		if (volume > 0) FlxG.sound.play(Paths.sound(sound, library), volume);

		FlxTween.color(bg, .5, bg.color, bgColorNew, { onComplete: cleanupTween });
		FlxTween.tween(this, { alpha: .8, y: padding + yOffset }, 1, { ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {
			new FlxTimer().start(3, function(tmr:FlxTimer) {
				FlxTween.tween(this, { x: FlxG.width, alpha: 0 }, 1, { ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {
					cleanupTween(twn);
					finished = true;
					destroy();
				} });
				cleanupTimer(tmr);
			});
			cleanupTween(twn);
		} });
	}
}