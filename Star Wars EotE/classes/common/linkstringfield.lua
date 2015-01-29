editmode = false;
hoverontext = false;

function setEditMode(state)
	if state then
		editmode = true;
		resetMenuItems();
		registerMenuItem("Stop editing", "stopedit", 5);

		setUnderline(false);
		setFocus();
		
		setCursorPosition(#getValue()+1);
		setSelectionPosition(0);
	else
		editmode = false;
		resetMenuItems();
		registerMenuItem("Edit", "edit", 4);
	end
end

function onInit()
	setEditMode(false);
end

function onHover(oncontrol)
	if not editmode then
		if not oncontrol then
			setUnderline(false);
			hoverontext = false;
		end
	end
end

function onHoverUpdate(x, y)
	if not editmode then
		if getIndexAt(x, y) < #getValue() then
			setUnderline(true);
			hoverontext = true;
		else
			setUnderline(false);
			hoverontext = false;
		end
	end
end

function onLoseFocus()
	setEditMode(false);
end

function onClickDown(button, x, y)
	if not editmode then
		if hoverontext then
			return true;
		else
			return false;
		end
	end
end

function onClickRelease(button, x, y)
	if not editmode and hoverontext then
		window[linktarget[1]].activate();
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not editmode then
		if hoverontext then
			draginfo.setType("shortcut");
			draginfo.setShortcutData(window[linktarget[1]].getValue());
			draginfo.setIcon(window[linktarget[1]].icon[1].normal[1])
			return true;
		else
			return false;
		end
	end
end

function onMenuSelection(...)
	setEditMode(not editmode);
end
