package freeplay;

import Discord.DiscordClient;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import freeplay.pages.*;
import flixel.FlxSprite;
import flixel.FlxG;

class FreeplayState extends MusicBeatState
{
	public static var lastStateSelected:Dynamic = null;
	private static var curSelected:Int = 0;

	public static var panelKeys:Array<String> = [ 'storymode', 'extras', 'covers' ];
	public static var unlocked:Map<String, Bool> = [ panelKeys[0] => true ];

	public static var panels:Map<String, Dynamic> = [
		panelKeys[0] => StoryMode,
		panelKeys[1] => Extras,
		panelKeys[2] => Covers
	];

	var outlineGroup:FlxSpriteGroup;
	var panelGroup:FlxSpriteGroup;

	var bg:FlxSprite;

	var deselectedColor:FlxColor = FlxColor.BLACK;
	var selectedColor:FlxColor = FlxColor.WHITE;

	var borderThickness:Float = 8;
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);

		bg = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		outlineGroup = new FlxSpriteGroup();
		panelGroup = new FlxSpriteGroup();

		bg.scrollFactor.set();

		outlineGroup.scrollFactor.set();
		panelGroup.scrollFactor.set();

		var doubleThickness:Float = borderThickness * 2;
		for (i in 0...panelKeys.length)
		{
			var name:String = panelKeys[i];
			var panel:FlxSprite = new FlxSprite().loadGraphic(Paths.image(#if !debug !freeplaySectionUnlocked(name) ? 'freeplay/locked' : #end 'freeplay/${Paths.formatToSongPath(name)}'));

			panel.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			panel.scrollFactor.set();

			panel.x = (panel.width + (doubleThickness * 2)) * i;
			var outline:FlxSprite = new FlxSprite(panel.x, panel.y).makeGraphic(Math.round(panel.width + doubleThickness), Math.round(panel.height + doubleThickness), FlxColor.WHITE);

			outline.ID = i;
			panel.ID = i;

			outlineGroup.add(outline);
			panelGroup.add(panel);
		};

		bg.screenCenter();
		add(bg);

		add(outlineGroup);
		add(panelGroup);

		outlineGroup.screenCenter();
		panelGroup.screenCenter();

		changeSelection();
		super.create();
	}

	public static function freeplaySectionUnlocked(name:String):Bool { return unlocked.exists(name) && unlocked.get(name); }
	public static function exitToFreeplay()
	{
		if (lastStateSelected != null) { MusicBeatState.switchState(Type.createInstance(lastStateSelected, [])); }
		else { MusicBeatState.switchState(new FreeplayState()); }
	}

	private function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.repeat(curSelected, change, panelKeys.length);
		for (outline in outlineGroup.members) outline.color = outline.ID == curSelected ? selectedColor : deselectedColor;
	}
	override function update(elapsed:Float)
	{
		var delta:Int = CoolUtil.boolToInt(controls.UI_RIGHT_P) - CoolUtil.boolToInt(controls.UI_LEFT_P);
		if (delta != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(delta);
		}
		if (controls.ACCEPT)
		{
			for (panel in panelGroup.members)
			{
				if (panel.ID == curSelected)
				{
					var name:String = panelKeys[curSelected];
					#if !debug if (!freeplaySectionUnlocked(name)) { FlxG.sound.play(Paths.sound('cancelMenu')); return; } #end
					if (panels.exists(name))
					{
						persistentUpdate = false;
						lastStateSelected = panels.get(name);

						FlxG.sound.play(Paths.sound('scrollMenu'));
						MusicBeatState.switchState(Type.createInstance(lastStateSelected, []));
					}
				}
			}
		}
		if (controls.BACK)
		{
			persistentUpdate = false;

			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}