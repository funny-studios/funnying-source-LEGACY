package;

import openfl.media.Sound;
import flixel.system.FlxSound;
import openfl.utils.Assets;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxSoundAsset;

using StringTools;
#if sys
import sys.FileSystem;
#end

class Hitsound
{
	private static var libraryPath:String = Paths.getLibraryPath('sounds/hitsounds/');
	private static var assetList:Array<String>;

	public static function formatToHitsound(string:String):String
	{
		var start:String = Paths.formatToSongPath(string.trim());
		return switch (start)
		{
			case 'default': 'hitsound';
			case 'top-10': 'topten';

			case '': 'none';
			default: start;
		};
	}

	public static function canPlayHitsound():Bool { return ClientPrefs.getPref('hitsoundVolume') > 0 && formatToHitsound(ClientPrefs.getPref('hitsound')) != 'none'; }
	public static function play(cache:Bool = false):Null<FlxSound>
	{
		if (assetList == null) assetList = Assets.list(SOUND);
		if (!canPlayHitsound()) return null;

		var playing:String = formatToHitsound(ClientPrefs.getPref('hitsound'));
		var asset:FlxSoundAsset = null;

		var path:String = 'hitsounds/$playing';
		var assetPath:String = 'sounds/$path';

		if (Paths.fileExists('$assetPath.${Paths.SOUND_EXT}', SOUND))
		{
			switch (cache)
			{
				case true: CoolUtil.precacheSound(path);
				default: asset = Paths.sound(path);
			}
		}
		else
		{
			var sounds:Array<FlxSoundAsset> = new Array<FlxSoundAsset>();
			for (asset in assetList)
			{
				if (asset.startsWith(libraryPath))
				{
					var arrayDir:Array<String> = asset.split('/');
					arrayDir.pop();
					if (arrayDir.pop() == playing)
					{
						var cached:Sound = Paths.saveSound(asset);
						if (!cache) sounds.push(cached);
					}
				}
			}
			if (!cache && sounds.length > 0) asset = FlxG.random.getObject(sounds);
		}

		if (!cache && asset != null) return FlxG.sound.play(asset, ClientPrefs.getPref('hitsoundVolume'));
		return null;
	}
}