package;

import Song;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;

	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;

	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;
	public static function getStage(SONG:SwagSong)
	{
		var curSong:String = SONG.song;
		return (SONG.stage != null) ? SONG.stage : curSong != null ? switch (Paths.formatToSongPath(curSong))
		{
			case 'tutorial': 'stage-compressed';

			case 'gastric-bypass' | 'roided' | 'jn' | 'funny-guy-snog': 'grass';
			case 'kleptomaniac': 'hell';

			case 'cervix' | 'intestinal-failure' | 'funny-duo': 'youtooz';
			case 'relapse': 'relapse';

			case 'squidgames': 'squidgame';
			case 'banana': 'minion';

			case 'braindead': 'mspaint';
			case 'the-kong': 'kong';

			case 'screwed': 'screwed';
			default: 'stage';
		} : 'stage';
	}
	public static function loadDirectory(SONG:SwagSong)
	{
		var stageFile:StageFile = getStageFile(getStage(SONG));
		forceNextDirectory = stageFile != null ? stageFile.directory : ''; // preventing crashes
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('stages/$stage.json');

		if (Assets.exists(path)) { rawJson = Assets.getText(path); }
		else { return null; }

		return cast Json.parse(rawJson);
	}
}