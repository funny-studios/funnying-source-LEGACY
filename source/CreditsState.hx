package;

import flixel.group.FlxGroup;
import Discord.DiscordClient;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class CreditsState extends MusicBeatState
{
	public static var selectedShit:Map<Int, Int> = new Map<Int, Int>();

	private static var notFirstSwitch:Bool = false;
	private static var crashIcon:Int = 0;

	private static var iFuckingHateCrash:Array<Array<Dynamic>> = [['crash', 'D61F51'], ['crashdream', '9FFF9E'], ['crash4chan', '70A76C']];

	private static var creditsStuff:Array<Array<Dynamic>> = [
		// Name - Icon name - Description - Link - BG Color
		['Funnying Team'],
		[
			'Pandemonium',
			'pandemonium',
			'Director/Main Programmer/Main Animator/Main Charter/Composer\n[ Kleptomaniac, Relapse, Banana, SQUIDGAMES ]',
			[
				'https://twitter.com/Paracosm_Daemon',
				'https://www.youtube.com/channel/UCw_6amwFem4xxGncDs3F01w',
				'https://gamebanana.com/members/2074221',
				'https://gamejolt.com/@Paracosm_Daemon',
				'https://www.roblox.com/users/3249138008/profile'
			],
			'3C084C'
		],
		[
			'Top 10 Awesome',
			'top_10',
			'Main Composer\n[ Cervix, Funny Duo, jn.ogg ]',
			[
				'https://twitter.com/top10awesome3',
				'https://www.youtube.com/c/Top10Awesome',
				'https://gamebanana.com/members/2045839',
				'https://www.roblox.com/users/3282717266/profile'
			],
			'FF9300'
		],
		[
			'Crash',
			iFuckingHateCrash[crashIcon][0],
			'Main Artist/Animator',
			['https://twitter.com/CRESHEATSTAMPON', 'https://gamebanana.com/members/2088706'],
			iFuckingHateCrash[crashIcon][1]
		],
		[
			'The J',
			'j',
			'Artist/Composer\n[ New versions of Gastric Bypass and Roided ]',
			[
				'https://twitter.com/Fwuffy_J',
				'https://www.youtube.com/channel/UCUbzTC7u5sBT--ZR6zJ5m1A',
				'https://www.roblox.com/users/3513131884/profile'
			],
			'99FFC3'
		],
		[
			'Mickey Toots',
			'mickey_tots',
			'Composer\n[ Funny Guy Snog, Funny Duo ]',
			[
				'https://twitter.com/MickeyToots_',
				'https://www.youtube.com/channel/UCF8dP9VIpVIMyXOikoL0xTQ'
			],
			'E94649'
		],
		[
			'Shinolad',
			'shinolad',
			'Charter\n[ Raw Charts for Gastric Bypass, Roided, and Intestinal Failure ]',
			[
				'https://twitter.com/ahonkingoose',
				'https://www.youtube.com/channel/UCeZvyB-7UYHPfLGgqF6M-Sw',
				'https://gamebanana.com/members/2034353'
			],
			'3B3B3B'
		],
		[
			'Joker',
			'joker',
			'Composer\n[ Intestinal Failure ]',
			'https://twitter.com/gko_jo',
			'7F7F7F'
		],
		[
			'Orichi',
			'orichi',
			'Composer\n[ Braindead ]',
			'https://twitter.com/orichi__',
			'FFAFCA'
		],
		['Mr Beast', 'mr_breast', 'Mr Beast', 'https://twitter.com/MrBeast', 'F2D3B5'],
		[''],
		['Very Special Thanks'],
		[
			'Joelx5',
			'joel',
			'Original creator of the Funny BF character art',
			'https://www.deviantart.com/joelbrunomanrique',
			'D41D22'
		],
		[
			'Jaob',
			'jaob',
			'Original creator of the Youtooz BF character art',
			'https://www.instagram.com/fakeemp3/',
			'FE916A'
		],
		[''],
		['Physics Engine Team'],
		[
			'Shadow Mario',
			'shadowmario',
			'Main Programmer of Physics Engine',
			'https://twitter.com/Shadow_Mario_',
			'444444'
		],
		[
			'RiverOaken',
			'river',
			'Main Artist/Animator of Physics Engine',
			'https://twitter.com/RiverOaken',
			'B42F71'
		],
		[
			'shubs',
			'shubs',
			'Additional Programmer of Physics Engine',
			'https://twitter.com/yoshubs',
			'5E99DF'
		],
		[''],
		['Former Engine Members'],
		[
			'bb-panzu',
			'bb',
			'Ex-Programmer of Physics Engine',
			'https://twitter.com/bbsub3',
			'3E813A'
		],
		[''],
		['Engine Contributors'],
		[
			'iFlicky',
			'flicky',
			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',
			'https://twitter.com/flicky_i',
			'9E29CF'
		],
		[
			'SqirraRNG',
			'sqirra',
			'Crash Handler and Base code for\nChart Editor\'s Waveform',
			'https://twitter.com/gedehari',
			'E1843A'
		],
		[
			'PolybiusProxy',
			'proxy',
			'.MP4 Video Loader Library (hxCodec)',
			'https://twitter.com/polybiusproxy',
			'DCD294'
		],
		[
			'KadeDev',
			'kade',
			'Fixed some cool stuff on Chart Editor\nand other PRs',
			'https://twitter.com/kade0912',
			'64A250'
		],
		[
			'Keoiki',
			'keoiki',
			'Note Splash Animations',
			'https://twitter.com/Keoiki_',
			'D2D2D2'
		],
		[
			'Nebula the Zorua',
			'nebula',
			'LUA JIT Fork and some Lua reworks',
			'https://twitter.com/Nebula_Zorua',
			'7D40B2'
		],
		[
			'Smokey',
			'smokey',
			'Sprite Atlas Support',
			'https://twitter.com/Smokey_5_',
			'483D92'
		],
		[''],
		["Funkin' Crew"],
		[
			'ninjamuffin99',
			'ninjamuffin99',
			"Programmer of Friday Night Funkin'",
			'https://twitter.com/ninja_muffin99',
			'CF2D2D'
		],
		[
			'PhantomArcade',
			'phantomarcade',
			"Animator of Friday Night Funkin'",
			'https://twitter.com/PhantomArcade3K',
			'FADC45'
		],
		[
			'evilsk8r',
			'evilsk8r',
			"Artist of Friday Night Funkin'",
			'https://twitter.com/evilsk8r',
			'5ABD4B'
		],
		[
			'kawaisprite',
			'kawaisprite',
			"Composer of Friday Night Funkin'",
			'https://twitter.com/kawaisprite',
			'378FC7'
		]
	];

	public static var curSelected:Int = -1;
	public static var curTeam:String = '';

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconGroup:FlxGroup;

	private var siteMap:Map<Int, CreditWebsite>;

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		iconGroup = new FlxGroup();

		add(bg);

		add(grpOptions);
		add(iconGroup);

		siteMap = new Map<Int, CreditWebsite>();
		switch (notFirstSwitch)
		{
			case true:
				crashIcon = FlxG.random.int(0, iFuckingHateCrash.length - 1);
			default:
				notFirstSwitch = true;
		}
		for (i in 0...creditsStuff.length)
		{
			var credits:Array<Dynamic> = creditsStuff[i];

			var isSelectable:Bool = !unselectableCheck(i);
			var creditedName:String = credits[0];

			var optionText:Alphabet = new Alphabet(0, 70 * i, creditedName, !isSelectable, false);

			optionText.isMenuItem = true;
			optionText.screenCenter(X);

			optionText.yAdd -= 70;
			if (isSelectable)
				optionText.x -= 50;

			optionText.forceX = optionText.x;
			// optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (isSelectable)
			{
				var creditsIcon:String = switch (Paths.formatToSongPath(creditedName))
				{
					case 'crash': iFuckingHateCrash[crashIcon][0];
					default: credits[1];
				}
				trace(creditsIcon);
				var icon:AttachedSprite = new AttachedSprite('credits/$creditsIcon');
				var siteIcon:CreditWebsite = new CreditWebsite(credits, optionText);

				siteIcon.ID = i;
				siteMap.set(i, siteIcon);

				if (selectedShit.exists(i))
					siteIcon.switchToSite(selectedShit.get(i));
				icon.antialiasing = false;

				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				// using an FlxGroup is NOT too much fuss! (smh........get beetter at prograning)
				iconGroup.add(icon);
				iconGroup.add(siteIcon);

				if (curSelected <= -1)
					curSelected = i;
			}
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);

		descBox.xAdd = -10;
		descBox.yAdd = -10;

		descBox.alphaMult = .6;
		descBox.alpha = .6;

		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER /*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);

		descText.scrollFactor.set();
		// descText.borderSize = 2.4;
		descBox.sprTracker = descText;
		add(descText);

		bg.color = getCurrentBGColor();
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + (.5 * elapsed), .7);
		if (!quitting)
		{
			if (creditsStuff.length > 1)
			{
				var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

				var downP:Bool = controls.UI_DOWN_P;
				var upP:Bool = controls.UI_UP_P;

				var delta:Int = CoolUtil.boolToInt(downP) - CoolUtil.boolToInt(upP);
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
						if (holdDelta != 0)
							changeSelection(holdDiff * shiftMult * holdDelta);
					}
				}
			}

			if (controls.ACCEPT && siteMap.exists(curSelected))
			{
				var credit:CreditWebsite = siteMap.get(curSelected);
				var link:String = credit.links[credit.curSite];

				if (link != null)
					CoolUtil.browserLoad(link); // creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				if (colorTween != null)
				{
					colorTween.cancel();
					colorTween.destroy();

					colorTween = null;
				}

				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());

				quitting = true;
			}
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
		for (item in grpOptions.members)
		{
			if (!item.isBold)
			{
				if (item.targetY == 0)
				{
					var lastX:Float = item.x;

					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x, lerpVal);

					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 300 - (50 * Math.abs(item.targetY)), lerpVal);
					item.forceX = item.x;
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		var iterated:Int = 0;
		do
		{
			curSelected = CoolUtil.repeat(curSelected, change, creditsStuff.length);

			if (change > 1)
			{
				iterated += change;
			}
			else
			{
				iterated++;
			}
		}
		while (unselectableCheck(curSelected) && iterated < creditsStuff.length);
		var soundToPlay:String = 'scrollMenu';

		var index:Int = curSelected;
		var offset:Int = 0;

		var selection:Array<Dynamic> = creditsStuff[curSelected];
		while (index > 0)
		{
			index--;

			var credit:Array<Dynamic> = creditsStuff[index];
			if (credit != null && unselectableCheck(index))
			{
				curTeam = Paths.formatToSongPath(credit[0]);
				switch (curTeam)
				{
					default:
					{
						descText.text = selection[2];
						descText.color = FlxColor.WHITE;
					}
				}
				break;
			}
		}
		FlxG.sound.play(Paths.sound(soundToPlay), .4);

		var newColor:Int = getCurrentBGColor(offset);
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
					twn.destroy();
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
				item.alpha = item.targetY == 0 ? 1 : .6;
		}

		descText.y = FlxG.height - descText.height + offsetThing - 10;
		if (moveTween != null)
			moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y: descText.y + 25}, .25, {ease: FlxEase.quartOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	function getCurrentBGColor(offset:Int = 0)
	{
		var selected:Array<Dynamic> = creditsStuff[curSelected];
		var bgColor:String = switch (Paths.formatToSongPath(selected[0]))
		{
			case 'crash': iFuckingHateCrash[crashIcon][1];
			default: selected[4 - offset];
		}

		if (!bgColor.startsWith('0x'))
			bgColor = '0xFF$bgColor';
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool
	{
		return creditsStuff[num].length <= 1;
	}
}
