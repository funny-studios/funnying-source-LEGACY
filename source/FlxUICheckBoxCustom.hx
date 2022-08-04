package;

import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUI.NamedBool;
import flixel.addons.ui.interfaces.ICursorPointable;
import flixel.addons.ui.interfaces.IFlxUIButton;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.addons.ui.interfaces.ILabeled;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;

/**
 * @author Lars Doucet
 */
class FlxUICheckBoxCustom extends FlxUIGroup implements ILabeled implements IFlxUIClickable implements IHasParams implements ICursorPointable
{
	public var box:FlxSprite;
	public var mark:FlxSprite;
	public var button:FlxUIButton;
	public var max_width:Float = -1;

	public var checked(default, set):Bool = false;
	public var params(default, set):Array<Dynamic>;

	// Set this to false if you just want the checkbox itself to be clickable
	public var textIsClickable:Bool = true;

	public var checkbox_dirty:Bool = false;

	public var textX(default, set):Float = 0;
	public var textY(default, set):Float = 0;

	public var box_space:Float = 2;

	public var skipButtonUpdate(default, set):Bool = false;

	public var callback:Void->Void;

	public static inline var CLICK_EVENT:String = "click_check_box";

	private function set_skipButtonUpdate(b:Bool):Bool
	{
		skipButtonUpdate = b;
		button.skipButtonUpdate = skipButtonUpdate;
		return skipButtonUpdate;
	}

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		params = p;
		if (params == null)
		{
			params = [];
		}
		var nb:NamedBool = {name: "checked", value: false};
		params.push(nb);
		return params;
	}

	private override function set_color(Value:Int):Int
	{
		if (button != null)
		{
			button.label.color = Value;
		}
		return super.set_color(Value);
	}

	public function new(X:Float = 0, Y:Float = 0, ?Box:Dynamic, ?Check:Dynamic, ?Label:String, ?LabelSize:Int = 8, ?LabelW:Int = 100, ?Font:String, ?Params:Array<Dynamic>, ?Callback:Void->Void)
	{
		super();

		callback = Callback;
		params = Params;

		// if null create a simple checkbox outline

		if (Box == null) Box = FlxUIAssets.IMG_CHECK_BOX;
		if ((Box is FlxSprite)) { box = cast Box; }
		else
		{
			box = new FlxSprite();
			box.loadGraphic(Box, true);
		}
		button = new FlxUIButton(0, 0, Label, _clickCheck);
		// set default checkbox label format
		button.label.setFormat(Font, LabelSize, 0xffffff, LEFT, OUTLINE);

		button.label.fieldWidth = LabelW;
		button.label.bold = true;

		button.up_color = 0xffffff;
		button.down_color = 0xffffff;
		button.over_color = 0xffffff;
		button.up_toggle_color = 0xffffff;
		button.down_toggle_color = 0xffffff;
		button.over_toggle_color = 0xffffff;

		button.loadGraphicSlice9(["", "", ""], Std.int(box.width + box_space + LabelW), Std.int(box.height));

		max_width = Std.int(box.width + box_space + LabelW);
		button.onUp.callback = _clickCheck; // for internal use, check/uncheck box, bubbles up to _externalCallback

		// if null load from default assets:
		if (Check == null) Check = FlxUIAssets.IMG_CHECK_MARK;
		if ((Check is FlxSprite)) { mark = cast Check; }
		else
		{
			mark = new FlxSprite();
			mark.loadGraphic(Check);
		}
		mark.setPosition(box.x + ((box.width - mark.width) / 2), box.y + ((box.height - mark.height) / 2));

		add(box);
		add(mark);
		add(button);

		anchorLabelX();
		anchorLabelY();

		checked = false;

		// set all these to 0
		button.setAllLabelOffsets(0, 0);

		x = X;
		y = Y;

		textX = 0;
		textY = 0; // forces anchorLabel() to be called and upate correctly
	}

	/*
		public function copy(?Params:Array<Dynamic>,?Callback:Void->Void):FlxUICheckBox {
			var boxAsset:String = box != null ? box.cachedGraphics.key : null;
			var checkAsset:String = mark != null ? mark.cachedGraphics.key : null;
			var label:String = (button != null && button.label != null) ? button.label.text : null;
			var labelW:Int = (label != null) ? Std.int(button.label.width) : 100;
			return new FlxUICheckBox(x, y, boxAsset, checkAsset, label, labelW, Params, Callback);
	}*/
	/**For ILabeled:**/
	public function setLabel(t:FlxUIText):FlxUIText
	{
		if (button == null) return null;
		button.label = t;
		return button.label;
	}

	public function getLabel():FlxUIText
	{
		if (button == null) return null;
		return button.label;
	}

	private override function set_visible(Value:Bool):Bool
	{
		// don't cascade to my members
		visible = Value;
		return visible;
	}

	private function anchorTime(f:FlxTimer):Void { anchorLabelY(); }
	private function set_textX(n:Float):Float
	{
		textX = n;
		anchorLabelX();

		return textX;
	}

	private function set_textY(n:Float):Float
	{
		textY = n;
		anchorLabelY();

		return textY;
	}

	public function anchorLabelX():Void { if (button != null) button.label.offset.x = -((box.width + box_space) + textX); }
	public function anchorLabelY():Void
	{
		if (button != null)
		{
			button.label.offset.y = ((box.height - button.label.offset.y) / 2) / 2;
			button.y = box.y + ((box.height - button.height) / 2) + textY;
		}
	}

	public override function destroy():Void
	{
		super.destroy();
		if (mark != null)
		{
			mark.destroy();
			mark = null;
		}
		if (box != null)
		{
			box.destroy();
			box = null;
		}
		if (button != null)
		{
			button.destroy();
			button = null;
		}
	}
	public var text(get, set):String;

	private function get_text():String { return button.label.text; }
	private function set_text(value:String):String
	{
		button.label.text = value;
		checkbox_dirty = true;

		return value;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (checkbox_dirty)
		{
			if (button.label != null)
			{
				if ((button.label is FlxUIText))
				{
					var ftu:FlxUIText = cast button.label;
					ftu.drawFrame(); // force update
				}

				anchorLabelX();
				anchorLabelY();

				button.width = box.frameWidth + box_space + button.label.textField.textWidth; // makes the clickable size exactly match the visible size of checkbox+label
				checkbox_dirty = false;
			}
		}
	}

	/*****GETTER/SETTER***/
	private function set_checked(b:Bool):Bool
	{
		mark.visible = b;
		return checked = b;
	}

	/*****PRIVATE******/
	private function _clickCheck():Void
	{
		if (!visible) return;
		checked = !checked;

		if (callback != null) callback();
		if (broadcastToFlxUI) FlxUI.event(CLICK_EVENT, this, checked, params);
	}
}