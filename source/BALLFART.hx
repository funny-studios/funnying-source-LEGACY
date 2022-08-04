package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
#if windows
import sys.io.Process;
#end
#if web
import js.html.Location;
import js.Browser;
#end
// crash handler stuff
#if CRASH_HANDLER
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

using StringTools;

class BALLFART extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = ClientPrefs.getPref('framerate'); // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var saveName:String = 'funnyingV15';
	public static var fpsVar:FPS;
	public static var whitelistedLocations:Array<String> = [
		'paracosm-daemon.itch.io',
		'itch.io',

		'gamejolt.net',
		'gamejolt.com',

		'127.0.0.1',
		'localhost'
	];
	// You can pretty much ignore everything from here on - your code should go in your states.
	public static function main():Void { Lib.current.addChild(new BALLFART()); }
	public function new()
	{
		super();

		if (stage != null) { init(); }
		else { addEventListener(Event.ADDED_TO_STAGE, init); }
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	private function setupGame():Void
	{
		var stageHeight:Int = Lib.current.stage.stageHeight;
		var stageWidth:Int = Lib.current.stage.stageWidth;

		if (zoom < 0)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;

			zoom = Math.min(ratioX, ratioY);

			gameHeight = Math.ceil(stageHeight / zoom);
			gameWidth = Math.ceil(stageWidth / zoom);
		}

		ClientPrefs.loadDefaultKeys();
		#if web
		// fuck kbh and other shitty websites that host funking mods...FUCK all of you. BITCHES.
		var newState:Class<FlxState> = TitleState;
		var location:Location = Browser.location;

		if (location != null)
		{
			var host:String = location.hostname;
			if (host == null || !whitelistedLocations.contains(host))
			{
				trace('$host not allowed crash and burn you motherfucker');
				newState = AntiPiracyState;
			}
		}
		#end
		addChild(new FlxGame(gameWidth, gameHeight, #if web newState #else initialState #end, zoom, framerate, framerate, skipSplash, startFullscreen));

		// #if (windows && debug)
		// try
		// {
		// 	var proc:Process = new Process('powershell', [
		// 		'Add-Type -AssemblyName System.Windows.Forms\n',

		// 		'$$global:balloon = New-Object System.Windows.Forms.NotifyIcon\n',
		// 		'Get-Member -InputObject $$global:balloon\n',

		// 		'[void](Register-ObjectEvent -InputObject $$balloon -EventName BalloonTipClicked -SourceIdentifier IconClicked -Action {\n',
		// 		'	#Perform cleanup actions on balloon tip\n',
		// 		'	$$global:balloon.dispose()\n',
		// 		'	Unregister-Event -SourceIdentifier IconClicked\n',
		// 		'	Remove-Job -Name IconClicked\n',
		// 		'	Remove-Variable -Name balloon -Scope Global\n',
		// 		'})\n',

		// 		'$$path = (Get-Process -id $$pid).Path\n',
		// 		'$$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($$path)\n',

		// 		'$$balloon.BalloonTipText = "......nuts"\n',
		// 		'$$balloon.BalloonTipTitle = "ballsack"\n',

		// 		'$$balloon.Text = "h"\n',

		// 		'$$balloon.Visible = $$true\n',
		// 		'$$balloon.ShowBalloonTip(5000)'
		// 	]);

		// 	trace(proc.stdout.readAll());
		// 	trace(proc.stderr.readAll());

		// 	proc.close();
		// }
		// catch (error:Dynamic) { trace(error); }
		// #end

		#if ANTICHEAT_ALLOWED addChild(new AntiCheatEngine()); #end
		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.getPref('showFPS');
		#end
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		#if html5
		FlxG.autoPause = false;
		#end
		FlxG.mouse.visible = false;
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = './crash/funnying_$dateNow.txt';
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += '\nUncaught Error: ${e.error}\nPlease report this error to the GitHub page: https://github.com/Paracosm-Daemon/Funnying-Source\n\n> Crash Handler written by: sqirra-rng';
		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();

		Sys.exit(1);
	}
	#end
}