package openfl.display;

import openfl.text.TextField;
import openfl.text.TextFormat;

/**
	i farted and a little poopy came out
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Skip extends TextField
{
	public function new(x:Float = 0, y:Float = 0, size:Int = 32, alpha:Float = 1, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		this.alpha = alpha;

		mouseEnabled = false;
		selectable = false;

		defaultTextFormat = new TextFormat("Comic Sans MS", size, color, true);

		multiline = false;
		autoSize = LEFT;

		text = "press ACCEPT to skip";
	}
}