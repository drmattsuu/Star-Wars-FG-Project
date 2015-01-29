function update()
	if targetcontrol then
		local sx, px, vx, sy, py, vy = targetcontrol.getScrollState();
		local tw, th = targetcontrol.getSize();

		th = th + 2*marginy

		if vy < sy then
			local pos = py/sy * th;
			local height = vy/sy * th;

			setAnchor("left", target[1], "right", "absolute", 1 + marginx);
			setAnchoredWidth(10);

			setAnchor("top", target[1], "top", "absolute", pos - marginy);
			setAnchoredHeight(height);
			
			setVisible(true);
		else
			setVisible(false);
		end
	end
end

function onInit()
	targetcontrol = window[target[1]];

	marginx = 0;
	marginy = 0;
	if barmargin and barmargin[1] and barmargin[1].x then
		marginx = barmargin[1].x[1];
	end
	if barmargin and barmargin[1] and barmargin[1].y then
		marginy = barmargin[1].y[1];
	end

	if targetcontrol then
		targetcontrol.onScroll = update;
	end
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if targetcontrol then
		if not dragging then
			local sx, px, vx, sy, py, vy = targetcontrol.getScrollState();
			
			dragstarty = y;
			dragstartpos = py;
			dragfactor = sy/vy;
		end
		
		dragging = true;
		targetcontrol.setScrollPosition(0, dragstartpos + (y - dragstarty)*dragfactor);
	end
	return true;
end

function onDragEnd()
	dragging = false;
end
