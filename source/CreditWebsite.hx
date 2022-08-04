package;

import shaders.ColorSwap;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

using StringTools;

class CreditWebsite extends FlxSpriteGroup
{
	private var websiteImages:Array<String> = ['roblox', 'twitter', 'youtube', 'gamejolt', 'instagram', 'deviantart', 'gamebanana'];
	private var colorSwap:ColorSwap;

	private var controls:Controls = PlayerSettings.player1.controls;

	private var iconOffset:Float = 0;
	private var iconWidth:Int = 150;

	public var icon:FlxSprite;
	public var label:FlxText;

	public var links:Array<String>;
	public var sites:Map<Int, FlxGraphic>;

	public var hasMultiple:Bool = false;
	public var curSite:Int = 0;

	public var sprTracker:Alphabet;

	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(credits:Array<Dynamic>, sprTracker:Alphabet)
	{
		super();
		this.sprTracker = sprTracker;

		sites = new Map<Int, FlxGraphic>();
		links = new Array<String>();

		scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);
		antialiasing = false;

		colorSwap = new ColorSwap();
		switch (Paths.formatToSongPath(credits[0]))
		{
			case 'gangster-spongebob': pushWebsiteGraphic(0, websiteImages[1], true);
		}

		var websites:Dynamic = credits[3 - (5 - credits.length)];
		if (websites != null)
		{
			switch (Std.isOfType(websites, String))
			{
				case true: { links.push(websites); pushToSites(0, websites); }
				default:
				{
					if (websites.length > 0)
					{
						trace('is array');

						var iter:Array<String> = websites;
						for (i in 0...iter.length)
						{
							var site:String = iter[i];
							links.push(site);

							pushToSites(i, site);
						}
					}
				}
			}
		}
		if (links.length > 0)
		{
			trace('Successfully found websites');
			icon = new FlxSprite();

			icon.scrollFactor.set(scrollFactor.x, scrollFactor.y);
			icon.antialiasing = antialiasing;

			icon.shader = colorSwap.shader;

			var iconExists:Bool = false;
			var picked:Int = -1;

			for (site => graphic in sites)
			{
				if (graphic != null)
				{
					iconExists = true;
					if (picked > site || picked < 0)
					{
						picked = site;
						curSite = site;

						icon.loadGraphic(graphic);
					}
				}
			}

			switch (exists)
			{
				default: icon.kill();
				case true:
				{
					icon.setGraphicSize(iconWidth, iconWidth);
					icon.updateHitbox();

					icon.setPosition(x, y);
				}
			}
			add(icon);
			if (links.length > 1)
			{
				trace('Has multiple sites, add label');
				colorSwap.brightness = -.5;

				label = new FlxText(0, 0, icon.width, getFormattedText(), 32);
				label.setFormat(Paths.font('comic.ttf'), label.size, FlxColor.WHITE, CENTER, NONE);

				repositionLabel();
				add(label);
			}
			repositionCredits();
		}
		else { kill(); }
	}
	public function repositionCredits()
	{
		if (icon.alive)
		{
			icon.setGraphicSize(iconWidth, iconWidth);
			icon.updateHitbox();

			icon.setPosition(x, y + iconOffset);
		}

		xAdd = -iconWidth - 10;
		setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
		alpha = sprTracker.alpha;
	}
	private function repositionLabel()
	{
		if (label != null)
		{
			var midpoint:Float = iconWidth / 2;

			label.text = getFormattedText();
			label.updateHitbox();

			label.setPosition(x + midpoint - (label.width / 2), y + midpoint - (label.height / 2));
		}
	}

	public function getWebsiteGraphic(site:String):FlxGraphic { return Paths.image('websites/$site'); }
	private function pushWebsiteGraphic(index:Int, site:String, force:Bool = false) { if (!sites.exists(index) || force) sites.set(index, getWebsiteGraphic(site)); }

	private function getFormattedText():String { return '${curSite + 1}/${links.length}'; }
	private function pushToSites(index:Int, site:String)
	{
		var split:Array<String> = site.split('://');
		if (split.length > 0)
		{
			var domain:Array<String> = split[1].split('.');

			while (domain.length > 2) domain.pop();
			if (domain.length > 0)
			{
				if (domain[0].trim().toLowerCase() == 'www') domain.shift();
				var tempName:String = domain[0];

				if (tempName != null)
				{
					var domainName:String = tempName.trim().toLowerCase();
					if (domainName.length > 0) pushWebsiteGraphic(index, domainName);
				}
			}
		}
	}

	public function switchToSite(newSite:Int)
	{
		curSite = CoolUtil.repeat(newSite, 0, links.length);
		CreditsState.selectedShit.set(ID, curSite);

		var newGraphic:FlxGraphic = sites[curSite];
		switch (newGraphic)
		{
			default:
			{
				icon.revive();
				if (icon.graphic != newGraphic)
				{
					trace('NEW GRAPHIC');
					icon.loadGraphic(newGraphic);

					icon.updateHitbox();
					icon.setPosition(x, y);
				}
			}
			case null: icon.kill();
		}
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		iconOffset = FlxMath.lerp(0, iconOffset, CoolUtil.boundTo(1 - (elapsed * 24), 0, 1));

		if (sprTracker.targetY == 0)
		{
			var delta:Int = CoolUtil.boolToInt(controls.UI_RIGHT_P) - CoolUtil.boolToInt(controls.UI_LEFT_P);
			if (delta != 0)
			{
				var changed:Bool = false;
				if (links.length > 1)
				{
					changed = true;
					switchToSite(curSite + delta);
				}
				else { angle = (angle + (delta * 90)) % 360; }

				FlxG.sound.play(Paths.sound(changed ? 'scrollMenu' : 'cancelMenu'), .4);
				iconOffset = 20 * (changed ? -1 : 1);
			}
		}

		repositionCredits();
		repositionLabel();
	}
}