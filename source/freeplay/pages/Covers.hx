package freeplay.pages;

class Covers extends ListState
{
	private static var storedSelection:Int = 0;
	override function create()
	{
		curSelected = storedSelection;
		weeks = ['screwed'];

		super.create();
	}
	override function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		super.changeSelection(change, playSound);
		storedSelection = curSelected;
	}
}