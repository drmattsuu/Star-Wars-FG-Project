labelwidget = nil;

function onInit()
	super.onInit();

	if label then
		labelwidget = addTextWidget("sheetlabelinline", string.upper(LanguageManager.getString(label[1])));
		local w,h = labelwidget.getSize();
		labelwidget.setPosition("bottomleft", w/2+1, h/2);
	end
	
end
