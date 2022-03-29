package;

import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import Song;

using StringTools;

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
}

class StageData {
	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:SwagSong) {
		var stage:String = (SONG.stage != null) ? SONG.stage : SONG.song != null ? switch(Paths.formatToSongPath(SONG.song))
		{
			case 'tutorial': 'stage-compressed';

			case 'gastric-bypass': 'grass';
			case 'kleptomaniac': 'hell';

			case 'cervix': 'youtooz';
			case 'relapse': 'relapse';

			case 'squidgames': 'squidgame';
			case 'banana': 'minion';

			case 'braindead': 'mspaint';
			default: 'stage';
		} : 'stage';

		var stageFile:StageFile = getStageFile(stage);
		forceNextDirectory = stageFile != null ? stageFile.directory : ''; //preventing crashes
	}

	public static function getStageFile(stage:String):StageFile {
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('stages/' + stage + '.json');

		if (Assets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		else
		{
			return null;
		}
		return cast Json.parse(rawJson);
	}
}