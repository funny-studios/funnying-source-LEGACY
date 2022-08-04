package freeplay.pages;

class Extras extends ListState
{
	private static var storedSelection:Int = 0;
	override function create()
	{
		curSelected = storedSelection;
		weeks = ['freeplay'];

		super.create();
	}
	override function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		super.changeSelection(change, playSound);
		storedSelection = curSelected;
	}
}