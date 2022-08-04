package freeplay;

import Discord.DiscordClient;
import WeekData;
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class ListState extends MusicBeatState
{
	private var songs:Array<SongMetadata> = [];
	private var weeks:Array<String>;

	var selector:FlxText;

	private var curSelected:Int = 0;

	var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var holdTime:Float = 0;
	override function create()
	{
		// Paths.clearStoredMemory(); also purposefully removed...
		// Paths.clearUnusedMemory(); purposefully removed shadowmario says

		persistentUpdate = true;
		PlayState.isStoryMode = false;

		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		WeekData.reloadWeekFiles(false, weeks);

		for (i in 0...WeekData.weeksList.length)
		{
			var week:String = weeks[i];
			if (WeekData.weeksLoaded.exists(week) #if !debug && !weekIsLocked(week) #end)
			{
				var leWeek:WeekData = WeekData.weeksLoaded.get(week);

				var leSongs:Array<String> = [];
				var leChars:Array<String> = [];

				for (j in 0...leWeek.songs.length)
				{
					var song:Dynamic = leWeek.songs[j];

					leSongs.push(song[0]);
					leChars.push(song[1]);
				}
				for (song in leWeek.songs)
				{
					var colors:Array<Int> = song[2];
					if (colors == null || colors.length < 3)
						colors = [255, 255, 255];
					addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				}
			}
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);

			songText.isMenuItem = true;
			songText.targetY = i;

			grpSongs.add(songText);
			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * .7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = .6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;

		add(diffText);
		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;

		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (lastDifficultyName == '')
			lastDifficultyName = CoolUtil.defaultDifficulty;
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = .6;
		add(textBG);

		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;

		var text:FlxText = new FlxText(textBG.x, textBG.y - 2, FlxG.width, leText, size);

		text.setFormat(Paths.font("comic.ttf"), size, FlxColor.WHITE, CENTER);
		text.scrollFactor.set();

		add(text);
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);

		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	override function update(elapsed:Float)
	{
		FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (.5 * elapsed), .7);

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= .01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');

		if (ratingSplit.length < 2)
			ratingSplit.push(''); // No decimals, add an empty space
		while (ratingSplit[1].length < 2)
			ratingSplit[1] += '0'; // Less than 2 decimals in it, add decimals then

		scoreText.text = 'PERSONAL BEST: $lerpScore (${ratingSplit.join('.')}%)';
		positionHighscore();

		var upP:Bool = controls.UI_UP_P;
		var downP:Bool = controls.UI_DOWN_P;
		var accepted:Bool = controls.ACCEPT;
		var ctrl:Bool = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;
		if (songs.length > 1)
		{
			var delta:Int = (CoolUtil.boolToInt(downP) - CoolUtil.boolToInt(upP)) * shiftMult;
			if (delta != 0)
			{
				changeSelection(delta);
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
					if (holdDelta != 0)
					{
						changeSelection(holdDiff * shiftMult * holdDelta);
						changeDiff();
					}
				}
			}
			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), .2);

				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		var delta:Int = CoolUtil.boolToInt(controls.UI_RIGHT_P) - CoolUtil.boolToInt(controls.UI_LEFT_P);

		if (delta != 0) { changeDiff(delta); }
		else if (upP || downP) { changeDiff(); }

		if (controls.BACK)
		{
			persistentUpdate = false;

			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new FreeplayState());
		}

		if (ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (accepted)
		{
			persistentUpdate = false;

			var songOriginal:String = songs[curSelected].songName;
			var songLowercase:String = Paths.formatToSongPath(songOriginal);

			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			switch (CoolUtil.getDifficultyFilePath(curDifficulty).trim().replace('-', '')) { case 'cuh': FlxG.sound.play(Paths.sound('cuh')); }

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;

			PlayState.storyDifficulty = curDifficulty;

			trace('CURRENT WEEK: ${WeekData.getWeekFileName()}');
			if (colorTween != null)
			{
				colorTween.cancel();
				colorTween.destroy();

				colorTween = null;
			}

			var completed:Bool = false;
			for (week => data in WeekData.weeksLoaded)
			{
				for (song in data.songs)
				{
					if (song[0] == songOriginal)
					{
						if (StoryMenuState.weekCompleted.exists(week) || data.hideStoryMode) completed = true;
						break;
					}
				}
			}

			if (FlxG.keys.pressed.SHIFT #if !debug && completed #end) { LoadingState.loadAndSwitchState(new ChartingState(), false, true); }
			else { LoadingState.loadAndSwitchState(new PlayState()); }

			FlxG.sound.music.volume = 0;
		}
		else if (controls.RESET)
		{
			persistentUpdate = false;

			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty = CoolUtil.repeat(curDifficulty, change, CoolUtil.difficulties.length);
		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	private function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), .4);
		curSelected = CoolUtil.repeat(curSelected, change, songs.length);

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
				colorTween.destroy();

				colorTween = null;
			}

			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
					twn.destroy();
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = .6;
		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = .6;
			if (item.targetY == 0) item.alpha = 1;
		}
		PlayState.storyWeek = songs[curSelected].week;
		for (i in 0...CoolUtil.difficulties.length) CoolUtil.difficulties.pop();

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;

		if (diffStr != null)
			diffStr = diffStr.trim(); // Fuck you HTML5
		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1)
						diffs.remove(diffs[i]);
				}
				--i;
			}

			if (diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}

		if (CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty)) { curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty))); }
		else { curDifficulty = 0; }

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos > -1)
			curDifficulty = newPos;
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);

		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}
class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;

		this.songCharacter = songCharacter;
		this.color = color;

		if (this.folder == null)
			this.folder = '';
	}
}