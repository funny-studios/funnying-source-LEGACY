import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class DisableMechanicsState extends MusicBeatState
{
	private static var prompt:String = "press ACCEPT to turn off mechanics,\notherwise press CANCEL to keep them on";

	private static var tooManyLetters:Int = 128;
	public static var deathAmount:Int = 3;

	var transitioning:Bool = false;
	var texts:Array<String>;

	var delta:Float = 0;
	var text:FlxText;

	override public function create()
	{
		Paths.clearStoredMemory();
		GameOverSubstate.resetVariables();

		FlxG.sound.playMusic(Paths.music('gameOver', 'shared'), .4, true);
		persistentUpdate = persistentDraw = true;

		var song:SwagSong = PlayState.SONG;
		var songName:String = song != null ? song.song : 'this song';

		texts = [
			'hey\nyou\'ve died a few times and it looks like you\'re struggling\nwanna turn off mechanics?\n\n$prompt',
			'so we noticed you died double the amount of times you did earlier\nare you sure you dont wanna turn off the mechanics?\n\nremember that you can $prompt',
			'i cannot tell if you are genuinely fucking insane\nfor the love of god, turn off the mechanics\n\njust $prompt',
			'you have a genuine mental illness\n\nremember to $prompt...',
			'you will be skinned on wednesday if you do not $prompt',
			'"wah wah this is so hard" my brother in christ you left the mechanics on\n\njust $prompt',
			'dont exit the fucking week you will have to replay week 1 again since week 2 is probably locked just switch the difficulty\n\njust $prompt',
			'I really wish you didnt "Lose games" You need to "Disable mechanic" To "Win Games" !\nSo $prompt !',
			'i would call you a slur but i think you\'re too soft to handle that mechanic\n\njust $prompt',
			'Skile Isue XD\n\n$prompt',
			'doing this shit doesn\'t unlock a secret or something stop trying and $prompt',
			'You will play Final Destination 0.003% Power 9 key God Mode Impossible Difficulty Hard if you do not $prompt',
			'press win+ctrl+d to turn off mechanics or $prompt',
			'this song has been programmed to loop!!1! you will never beat it unless you $prompt!!!',
			'press 7 clear notes press enter\n\nor $prompt',
			'you have 2 minutes to $prompt.',
			'you can disable these like you can disable the nut on a string btw\n\njust $prompt',
			'Okay. I\'m still making the eventless alt file. But I think it\'s time I told you WHY $songName is so RAW.\nI purposely made the RAW so it\'d be a bit harder to play, I was trying to make a unique mechanic. Tricky has his hurt notes, Shaggy has more arrows, Gold has his Unowns, Hypno has his nut on a string, funny bf has his RAW. And as for the people complaining about the funny bf making them RAW....\n\nTHAT\'S THE POINT!\n\nI have no intentions to trigger anything. But the fact that the RAW is RAW for people just means I\'ve done my job. Most RAW films and games has something that RAWs the viewer. Whether that be funny bf, or RAW. Hell! The original funny bf apparently has something to RAW that it drove someone to play funny bf instantly! While that obviously wasn\'t my intent I did expect some RAW and that\'s what I was going for. So thank you for telling me I did my job RAW :3.\n\n$prompt',
			'wanna pass this song? go to FUNK (dot) gg to redeem your friday night funkin prize!\n\nor, $prompt!',
			'You fucking suck at this game, do you wanna disable the mechanics or keep crying for hours trying to beat this song\n\nIf yes, $prompt',
			'you ba d. At this Game.Enable MOREBIUS or $prompt',
			'lose 4 free goblincoins or $prompt',
			'please delete this mod seriously there\'s better things you can do with this  whole gigabyte of space\n\nor just $prompt',
			'how 2 win 1 simple trick turn the off by pressing ACCEPT',
			'press ACCEPT to sacrifice your newborn to make this song possible',
			'Hi.Your.deaded  Many time....... You are.mabye Stugles....... Wan\'t \nTurn Of " Mechanism"\n\nPress " ACEPT if Youre.are Want Mechanical. Of,,......\nOr .PRESS.THE Canal" Buthton To..KEEP THENM........................................ Form the.beast gamer;',
			'you better fucking listen to beast gaming and turn off the mechanics by pressing ACCEPT',
			'press ACCEPT to keep the mechanics and cancel to turn them off :joy:',
			'press CANCEL to keep the mechanics and enter to turn them off :joy:',
			'are you disabled? (press ACCEPT)',
			'you might as well disable mechanics by pressing ACCEPT because you\'re so fucking shit at this game. i doubt you\'d even get past without them - joker',
			'Ok.If  do Not Disable mechanic.I Will "Eat" your Grandma. Ash,so,$prompt',
			'lil baby u need to turn the mechanics off to win since ur so SHIT so $prompt\n\n-orichi',
			'if you dont disable mechanics the helicopter will come to steal your horse cheese farm. you will lose all horses and become kleptomaniac so $prompt',
			'the pirates are comiong to. STEALER YOURTREASURE!! press ACCEPT to stop them!',
			'avoid the fucking horse cheese notes you dumbass',
			'are you gonna continue getting horse cheesed or are you gonna be smart and turn the fucking mechanics off\n\n$prompt',
			'Funny bf will come to your house!!!!! Unless youre turn off mechanic... so $prompt',
			'if you dont turj of thr menchanuc tiu wul DIE so $prompt',
			'disable mechanis... do the funny... $prompt...',
			'press cancel to replace every song in freeplay with braindead old',
			'PRESS accept press ACCEPT do it now PRESS IT',
			'if you disble the mechanic you fucking kill die so $prompt and die',
			'press alt f 4 it doeas the kill yourslef or $prompt',
			'you might as well press accept since you fucking suck at this game - joker',
			'press accept for free money on cashapp',
			'press accept to fufill orichi\'s chronic loneliness',
			'press accept or the boogie monster gets you',
			'well clearly you\'re so fucking ignorant that you just won\'t press accept, so this will loop if you keep the mechanics on\n\n$prompt'
		];

		var index:Int = Std.int(Math.max((Math.ceil(Math.max(PlayState.deathCounter, deathAmount) / deathAmount) - 1), 0) % texts.length);
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('diedtoomanytimes'));

		var str:String = texts[index] != null ? texts[index] : prompt;

		text = new FlxText(0, 0, FlxG.width * .8, str, Math.round(32 * CoolUtil.boundTo(tooManyLetters / str.length, .5, 1)));
		text.setFormat(Paths.font('comic.ttf'), text.size, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);

		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		text.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		bg.setGraphicSize(-1, FlxG.height);
		bg.updateHitbox();

		bg.screenCenter();

		text.screenCenter(Y);
		text.x = text.size;

		add(bg);
		add(text);

		super.create();
		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		text.screenCenter(Y);

		delta = (delta + (elapsed * 2)) % (Math.PI * 2);

		text.y += (Math.sin(delta * 2) * 4);
		text.angle = Math.sin(delta);

		if (!transitioning)
		{
			var accept:Bool = controls.ACCEPT;
			var back:Bool = controls.BACK;

			if (accept || back)
			{
				transitioning = true;
				persistentUpdate = false;

				PlayState.mechanicsEnabled = !accept;

				FlxG.sound.play(Paths.sound(accept ? 'confirmMenu' : 'cancelMenu'), .5);
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
				{
					FlxG.sound.music.fadeOut(1, 0, function(twn:FlxTween)
					{
						FlxTransitionableState.skipNextTransIn = true;
						#if debug
						if (back && TitleState.loopingDisableMechanics)
						{
							if (PlayState.deathCounter < deathAmount) PlayState.deathCounter = deathAmount;

							PlayState.deathCounter += deathAmount;
							MusicBeatState.switchState(new DisableMechanicsState());

							return;
						}
						#end
						switch (TitleState.loopingDisableMechanics)
						{
							default: MusicBeatState.switchState(new PlayState());
							// fuck you!!!!!!
							#if debug
							case true:
							{
								PlayState.deathCounter = 0;

								TitleState.loopingDisableMechanics = false;
								PlayState.mechanicsEnabled = true;

								TitleState.playTitleMusic();
								MusicBeatState.switchState(new MainMenuState());
							}
							#end
						}
					});
				}, true);
			}
		}
	}
}