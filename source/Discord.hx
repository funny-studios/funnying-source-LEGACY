package;

import Sys.sleep;
#if (desktop && !neko)
import discord_rpc.DiscordRpc;
#end
using StringTools;

class DiscordClient
{
	private static var largeText:String = "dead family(eaf myil(dead child dead family DEAFD FAMILY DEAD FAMILY)ORPHANGAGEd)I burnt down anfdead";
	#if (desktop && !neko)
	private static var curPresence:DiscordPresenceOptions;
	#end

	public function new()
	{
		#if (desktop && !neko)
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "936804088807571457",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");
		while (true)
		{
			if (curPresence != null)
			{
				DiscordRpc.presence(curPresence);
				curPresence = null;
			}
			DiscordRpc.process();
			sleep(2);
			//trace("Discord Client Update");
		}
		DiscordRpc.shutdown();
		#end
	}

	public static function shutdown()
	{
		#if (desktop && !neko)
		DiscordRpc.shutdown();
		#end
	}

	static function onReady()
	{
		#if (desktop && !neko)
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'iconog',
			largeImageText: largeText
		});
		#end
	}

	static function onError(_code:Int, _message:String) { trace('Error! $_code : $_message'); }

	static function onDisconnected(_code:Int, _message:String) { trace('Disconnected! $_code : $_message'); }

	public static function initialize()
	{
		var DiscordDaemon = sys.thread.Thread.create(() -> { new DiscordClient(); });
		trace("Discord Client initialized");
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		#if (desktop && !neko)
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;
		if (endTimestamp > 0 && hasStartTimestamp) endTimestamp = startTimestamp + endTimestamp;

		curPresence = {//DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'iconog',
			largeImageText: largeText,
			smallImageKey : smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : hasStartTimestamp ? Std.int(startTimestamp / 1000) : null,
            endTimestamp : hasStartTimestamp ? Std.int(endTimestamp / 1000) : null
		};//);
		#end
		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}
