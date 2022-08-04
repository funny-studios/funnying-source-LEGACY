package options;

using StringTools;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Controller Mode', 'Check this if you want to play with\na controller instead of using your Keyboard.',
			'controllerMode', 'bool', false);
		addOption(option);

		// I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', // Name
			'If checked, notes go Down instead of Up, simple enough.', // Description
			'downScroll', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);

		var option:Option = new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll', 'bool', false);
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping', 'bool', true);
		addOption(option);

		var option:Option = new Option('Mechanics', "If checked, mechanics (i.e horse cheese notes)\nwill be enabled.",
			'mechanics', 'bool', true);
		addOption(option);

		option.onChange = onMechanicsChanged;

		var option:Option = new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset', 'bool', false);
		addOption(option);

		var option:Option = new Option('Hitsound', "The type of hitsound you want to use.", 'hitsound', 'string', 'Default', ['Default', 'Funnying', 'Top 10', 'HIT_2', 'BF']);
		addOption(option);
		option.onChange = onHitsoundChanged;

		var option:Option = new Option('Hitsound Volume', "The volume your hitsound plays at when a note is hit.", 'hitsoundVolume', 'percent', 0);
		addOption(option);

		option.onChange = onHitsoundChanged;
		option.scrollSpeed = 1.6;

		option.minValue = 0;
		option.maxValue = 1;

		option.changeValue = .05;
		option.decimals = 2;

		// var option:Option = new Option('Rating Offset',
		// 	'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
		// 	'ratingOffset',
		// 	'int',
		// 	0);
		// option.displayFormat = '%vms';
		// option.scrollSpeed = 20;
		// option.minValue = -30;
		// option.maxValue = 30;
		// addOption(option);

		super();
	}

	function onMechanicsChanged():Void { PlayState.mechanicsEnabled = ClientPrefs.getPref('mechanics'); }
	function onHitsoundChanged():Void { Hitsound.play(); }
}
