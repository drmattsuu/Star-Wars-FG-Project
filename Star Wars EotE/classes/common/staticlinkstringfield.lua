hoverontext = false;

function onHover(oncontrol)
	if not oncontrol then
		setUnderline(false);
		hoverontext = false;
	end
end

function onHoverUpdate(x, y)
	if getIndexAt(x, y) < #getValue() then
		setUnderline(true);
		hoverontext = true;
	else
		setUnderline(false);
		hoverontext = false;
	end
end

function onClickDown(button, x, y)
	if hoverontext then
		return true;
	else
		return false;
	end
end

function onClickRelease(button, x, y)
	if hoverontext then
		if self.activate then
			self.activate();
		else
			window[linktarget[1]].activate();
		end
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if linktarget and hoverontext then
		if window[linktarget[1]].onDragStart then
			return window[linktarget[1]].onDragStart(button, x, y, draginfo);
		end
	else
		return false;
	end
end
