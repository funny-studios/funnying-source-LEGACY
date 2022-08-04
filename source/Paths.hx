package;

import flixel.system.FlxSound;
import flash.media.Sound;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/funnyMenu.$SOUND_EXT',
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") { getPreloadPath(file); } else { getLibraryPathForce(file, library); }
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	static public function video(key:String)
	{
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound { return returnSound('sounds', key, library); }
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String) { return sound(key + FlxG.random.int(min, max), library); }

	inline static public function music(key:String, ?library:String):Sound { return returnSound('music', key, library); }
	inline static public function voices(song:String):Any
	{
		var path:String = '${formatToSongPath(song)}/Voices';

		if (Assets.exists('songs:' + getPath('songs/$path.$SOUND_EXT', SOUND), SOUND)) return returnSound('songs', path);
		return null;
	}
	inline static public function inst(song:String):Any
	{
		var path:String = '${formatToSongPath(song)}/Inst';

		if (Assets.exists('songs:' + getPath('songs/$path.$SOUND_EXT', SOUND), SOUND)) return returnSound('songs', path);
		return null;
	}

	inline static public function image(key:String, ?library:String):FlxGraphic { return returnGraphic(getPath('images/$key.png', IMAGE, library)); }
	static public function getTextFromFile(key:String):String
	{
		#if sys
		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String) { return 'assets/fonts/$key'; }
	inline static public function fileExists(key:String, type:AssetType) { return OpenFlAssets.exists(getPath(key, type)); }

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames { return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library)); }
	inline static public function getPackerAtlas(key:String, ?library:String) { return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library)); }

	inline static public function formatToSongPath(path:Null<String>):Null<String>
	{
		// A file name can't contain any of the following characters:
		// \ / : * ? " < > |
		return
		path != null
		? path.trim()
			.toLowerCase()
			.replace(' ', '-')
			.replace('\\', '')
			.replace('/', '')
			.replace(':', '')
			.replace('*', '')
			.replace('?', '')
			.replace('"', '')
			.replace("'", '')
			.replace('<', '')
			.replace('>', '')
			.replace('|', '')
		: null;
	}
	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(path:String):Null<FlxGraphic>
	{
		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);

				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no $path is returning null NOOOO');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function saveSound(path:String, ?key:String = null):Sound
	{
		var gottenPath:String = path.substring(path.indexOf(':') + 1, path.length);
		if (!currentTrackedSounds.exists(gottenPath)) //currentTrackedSounds.set(path, Sound.fromFile('./$path'));
		{
			var folder:String = key == 'songs' ? 'songs:' : '';
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + path));
		}

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}
	public static function returnSound(path:String, key:String, ?library:String = null):Sound
	{
		// I hate this so god damn much
		// trace(gottenPath);
		return saveSound(getPath('$path/$key.$SOUND_EXT', SOUND, library), path);
	}
}