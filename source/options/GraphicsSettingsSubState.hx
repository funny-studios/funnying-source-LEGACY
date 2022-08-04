package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

using StringTools;


class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence

		// I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', // Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);

		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing', 'bool', true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		#if !html5 // Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate', "Sets the game's framerate to the selected value.", 'framerate', 'int', 60);
		addOption(option);

		option.minValue = 30;
		option.maxValue = 480;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		/*
			var option:Option = new Option('Persistent Cached Data',
				'If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
				'imagesPersist',
				'bool',
				false);
			option.onChange = onChangePersistentData; //Persistent Cached Data changes FlxGraphic.defaultPersist
			addOption(option);
		 */

		super();
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; // Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; // Don't judge me ok
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
			{
				sprite.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			}
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.getPref('framerate') > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.getPref('framerate');
			FlxG.drawFramerate = ClientPrefs.getPref('framerate');
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.getPref('framerate');
			FlxG.updateFramerate = ClientPrefs.getPref('framerate');
		}
	}
}