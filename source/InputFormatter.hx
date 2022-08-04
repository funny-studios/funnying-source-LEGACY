import flixel.input.keyboard.FlxKey;

using StringTools;

class InputFormatter
{
	public static function getKeyName(key:FlxKey):String
	{
		return switch (key)
		{
			case BACKSPACE:
				"BckSpc";
			case CONTROL:
				"Ctrl";
			case ALT:
				"Alt";
			case CAPSLOCK:
				"Caps";
			case PAGEUP:
				"PgUp";
			case PAGEDOWN:
				"PgDown";
			case ZERO:
				"0";
			case ONE:
				"1";
			case TWO:
				"2";
			case THREE:
				"3";
			case FOUR:
				"4";
			case FIVE:
				"5";
			case SIX:
				"6";
			case SEVEN:
				"7";
			case EIGHT:
				"8";
			case NINE:
				"9";
			case NUMPADZERO:
				"#0";
			case NUMPADONE:
				"#1";
			case NUMPADTWO:
				"#2";
			case NUMPADTHREE:
				"#3";
			case NUMPADFOUR:
				"#4";
			case NUMPADFIVE:
				"#5";
			case NUMPADSIX:
				"#6";
			case NUMPADSEVEN:
				"#7";
			case NUMPADEIGHT:
				"#8";
			case NUMPADNINE:
				"#9";
			case NUMPADMULTIPLY:
				"#*";
			case NUMPADPLUS:
				"#+";
			case NUMPADMINUS:
				"#-";
			case NUMPADPERIOD:
				"#.";
			case SEMICOLON:
				";";
			case COMMA:
				",";
			case PERIOD:
				".";
			// case SLASH:
			//	"/";
			case GRAVEACCENT:
				"BckTck";
			case LBRACKET:
				"[";
			case RBRACKET:
				"]";
			case QUOTE:
				"'";
			case PRINTSCREEN:
				"PrtScrn";
			case NONE: '---';
			default:
			{
				var label:String = '' + key;
				if (label.toLowerCase() == 'null')
					'---';
				'' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
			}
		}
	}
}