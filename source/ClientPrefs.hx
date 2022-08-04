package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

class ClientPrefs
{
	// A map of every user-made preference
	public static var prefs:Map<String, Dynamic> = [
		// FUNNYING
		'hitsound' => 'Default', // String
		'scrollUnderlay' => 0, // WHY IS THIS NOT IN NATIVE PHYSICS	// Float
		'reducedMotion' => false, // Bool
		'subtitles' => true, // Bool
		'mechanics' => true, // Bool
		// PHYSICS ENGINE
		'healthBarAlpha' => 1, // Float
		'hitsoundVolume' => 0, // Float
		'globalAntialiasing' => true, // Bool
		'controllerMode' => false, // Bool
		'opponentStrums' => true, // Bool
		'middleScroll' => false, // Bool
		'ghostTapping' => true, // Bool
		'noteSplashes' => true, // Bool
		'downScroll' => false, // Bool
		'lowQuality' => false, // Bool
		'scoreZoom' => true, // Bool
		'noReset' => false, // Bool
		'flashing' => true, // Bool
		'camZooms' => true, // Bool
		'hideHud' => false, // Bool
		'showFPS' => false, // Bool
		'timeBarType' => 'Time Left', // String
		'pauseMusic' => 'Pulse', // String
		'noteOffset' => 0, // Int
		'framerate' => 60, // Int
		'comboOffset' => [0, 0, 0, 0, 0, 0], // Array<Int>
		'ratingOffset' => 0, // Int
		'funnyWindow' => 45, // Int
		'googWindow' => 90, // Int
		'badWindow' => 135, // Int
		'safeFrames' => 10 // Int
	];
	// For custom functions after the save data is loaded
	public static var loadFunctions:Map<String, (Dynamic) -> Void> = [
		'showFPS' => function(showFPS:Bool)
		{
			if (BALLFART.fpsVar != null)
				BALLFART.fpsVar.visible = showFPS;
		},
		'framerate' => function(framerate:Int)
		{
			// trace('framerate $framerate');
			if (framerate > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			}
			else
			{
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		},
		'customControls' => function(controls:Map<String, Array<FlxKey>>)
		{
			// trace('reload controls');
			reloadControls();
		}
	];
	// Flixel data to load, i.e 'muted' or 'volume'
	public static var flixelData:Map<String, String> = ['volume' => 'volume', 'mute' => 'muted'];
	// Maps like gameplaySettings
	public static var mapData:Map<String, Array<Dynamic>> = [
		// FlxG.save.data.*		Class, Map Name
		'gameplaySettings' => [ClientPrefs, 'gameplaySettings'],
		'customControls' => [ClientPrefs, 'keyBinds']
	];
	// For stuff that needs to be in the controls_v2 save
	public static var separateSaves:Array<String> = ['customControls'];
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'botplay' => false
	];
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [W, UP],
		'note_right' => [D, RIGHT],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_up' => [W, UP],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R, NONE],
		'volume_mute' => [ZERO, NONE],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN, NONE],
		'debug_2' => [EIGHT, NONE]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		// trace(defaultKeys);
	}

	public static function saveSettings()
	{
		var save:Dynamic = FlxG.save.data;
		for (setting => value in prefs)
		{
			// trace('saving $setting!');
			Reflect.setField(save, setting, value);
		}
		for (savedAs => map in mapData)
		{
			// trace('saving map $savedAs as ${map[1]}!');
			if (!separateSaves.contains(savedAs))
				Reflect.setField(save, savedAs, Reflect.field(map[0], map[1]));
		}

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('FUNNYING_CONTROLS', BALLFART.saveName); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff

		for (name in separateSaves)
		{
			// trace('saving $name in separate save!');
			if (prefs.exists(name))
			{
				Reflect.setField(save.data, name, prefs.get(name));
				continue;
			}
			if (mapData.exists(name))
			{
				var map:Array<Dynamic> = mapData.get(name);
				Reflect.setField(save.data, name, Reflect.field(map[0], map[1]));
				continue;
			}
		}

		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		var save:Dynamic = FlxG.save.data;
		for (setting => _ in prefs) // _ is unused
		{
			var value:Dynamic = Reflect.field(save, setting);
			if (value != null)
			{
				// trace('loading $setting!');

				prefs.set(setting, value);
				if (loadFunctions.exists(setting))
					loadFunctions.get(setting)(value); // Call the load function
			}
		}
		// flixel automatically saves your volume!
		for (setting => name in flixelData)
		{
			// trace('loading flixel $setting!');

			var value:Dynamic = Reflect.field(save, setting);
			if (value != null)
				Reflect.setField(FlxG.sound, name, value);
		}
		// This needs to be loaded differently
		for (savedAs => map in mapData)
		{
			if (!separateSaves.contains(savedAs))
			{
				var data:Map<Dynamic, Dynamic> = Reflect.field(save, savedAs);
				if (data != null)
				{
					// trace('loading map $savedAs as ${map[1]}!');
					var loadTo:Dynamic = Reflect.field(map[0], map[1]);
					for (name => value in data)
					{
						if (loadTo.exists(name))
							loadTo.set(name, value);
					}
					if (loadFunctions.exists(savedAs))
						loadFunctions.get(savedAs)(loadTo); // Call the load function
				}
			}
		}

		var save:FlxSave = new FlxSave();
		save.bind('FUNNYING_CONTROLS', BALLFART.saveName);
		if (save != null)
		{
			for (name in separateSaves)
			{
				var data:Dynamic = Reflect.field(save.data, name);
				if (data != null)
				{
					// trace('loading $name in separate save!');
					if (prefs.exists(name))
					{
						prefs.set(name, data);
						continue;
					}
					if (mapData.exists(name))
					{
						var map:Array<Dynamic> = mapData.get(name);
						var loadTo:Dynamic = Reflect.field(map[0], map[1]);

						// trace('loading map $name as ${map[1]}!');
						for (name => value in cast(data, Map<Dynamic, Dynamic>))
						{
							if (loadTo.exists(name))
								loadTo.set(name, value);
						}
						if (loadFunctions.exists(name))
							loadFunctions.get(name)(loadTo); // Call the load function
						continue;
					}
				}
			}
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	inline public static function getPref(name:String, ?defaultValue:Dynamic):Dynamic
	{
		if (prefs.exists(name))
			return prefs.get(name);
		return defaultValue;
	}

	public static function reloadControls()
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));

		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();

		var len:Int = copiedArray.length;
		var i:Int = 0;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				i--;
			}

			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
