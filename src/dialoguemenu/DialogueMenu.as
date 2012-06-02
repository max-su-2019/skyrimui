import gfx.io.GameDelegate;
import Components.CrossPlatformButtons;
import Shared.GlobalFunc;
import gfx.managers.FocusHandler;
import gfx.ui.InputDetails;
import gfx.ui.NavigationCode;

class DialogueMenu extends MovieClip
{
	static var ALLOW_PROGRESS_DELAY: Number = 750;
	static var iMouseDownExecutionCount: Number = 0;
	
	static var SHOW_GREETING: Number = 0;
	static var TOPIC_LIST_SHOWN: Number = 1;
	static var TOPIC_CLICKED: Number = 2;
	static var TRANSITIONING: Number = 3;
	
    
	var ExitButton: CrossPlatformButtons;
	var SpeakerName: TextField;
	var SubtitleText: TextField;
	var TopicList: MovieClip;
	var TopicListHolder: Object;
	var bAllowProgress: Boolean;
	var bFadedIn: Boolean;
	var eMenuState: Number;
	var iAllowProgressTimerID: Number;

	function DialogueMenu()
	{
		super();
		TopicList = TopicListHolder.List_mc;
		eMenuState = DialogueMenu.SHOW_GREETING;
		bFadedIn = true;
		bAllowProgress = false;
	}

	function InitExtensions()
	{
		Mouse.addListener(this);
		
		GameDelegate.addCallBack("Cancel", this, "onCancelPress");
		GameDelegate.addCallBack("ShowDialogueText", this, "ShowDialogueText");
		GameDelegate.addCallBack("HideDialogueText", this, "HideDialogueText");
		GameDelegate.addCallBack("PopulateDialogueList", this, "PopulateDialogueLists");
		GameDelegate.addCallBack("ShowDialogueList", this, "DoShowDialogueList");
		GameDelegate.addCallBack("StartHideMenu", this, "StartHideMenu");
		GameDelegate.addCallBack("SetSpeakerName", this, "SetSpeakerName");
		GameDelegate.addCallBack("NotifyVoiceReady", this, "OnVoiceReady");
		GameDelegate.addCallBack("AdjustForPALSD", this, "AdjustForPALSD");
		
		TopicList.addEventListener("listMovedUp", this, "playListUpAnim");
		TopicList.addEventListener("listMovedDown", this, "playListDownAnim");
		TopicList.addEventListener("itemPress", this, "onItemSelect");
		
		GlobalFunc.SetLockFunction();
		
		ExitButton.Lock("BR");
		ExitButton._x = ExitButton._x - 50;
		ExitButton._y = ExitButton._y - 30;
		ExitButton.addEventListener("click", this, "onCancelPress");
		
		TopicListHolder._visible = false;
		TopicListHolder.TextCopy_mc._visible = false;
		TopicListHolder.TextCopy_mc.textField.textColor = 0x606060;
		TopicListHolder.TextCopy_mc.textField.verticalAutoSize = "top";
		TopicListHolder.PanelCopy_mc._visible = false;
		
		FocusHandler.instance.setFocus(TopicList, 0);
		
		SubtitleText.verticalAutoSize = "top";
		SubtitleText.SetText(" ");
		
		SpeakerName.verticalAutoSize = "top";
		SpeakerName.SetText(" ");
	}

	function AdjustForPALSD()
	{
		_root.DialogueMenu_mc._x = _root.DialogueMenu_mc._x - 35;
	}

	function SetPlatform(aiPlatform: Number, abPS3Switch: Boolean)
	{
		ExitButton.SetPlatform(aiPlatform, abPS3Switch);
		TopicList.SetPlatform(aiPlatform, abPS3Switch);
	}

	function SetSpeakerName(strName)
	{
		SpeakerName.SetText(strName);
	}

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		if (bFadedIn && GlobalFunc.IsKeyPressed(details)) {
			if (details.navEquivalent == NavigationCode.TAB) {
				onCancelPress();
			} else if ((details.navEquivalent != NavigationCode.UP && details.navEquivalent != NavigationCode.DOWN) || eMenuState == DialogueMenu.TOPIC_LIST_SHOWN) {
				pathToFocus[0].handleInput(details, pathToFocus.slice(1));
			}
		}
		return true;
	}

	function get menuState()
	{
		return eMenuState;
	}

	function set menuState(aNewState)
	{
		eMenuState = aNewState;
	}

	function ShowDialogueText(astrText)
	{
		SubtitleText.SetText(astrText);
	}

	function OnVoiceReady()
	{
		StartProgressTimer();
	}

	function StartProgressTimer()
	{
		bAllowProgress = false;
		clearInterval(iAllowProgressTimerID);
		iAllowProgressTimerID = setInterval(this, "SetAllowProgress", DialogueMenu.ALLOW_PROGRESS_DELAY);
	}

	function HideDialogueText()
	{
		SubtitleText.SetText(" ");
	}

	function SetAllowProgress()
	{
		clearInterval(iAllowProgressTimerID);
		bAllowProgress = true;
	}

	function PopulateDialogueLists()
	{
		var topicDataStride: Number = 3;
		var topicTextOffset: Number = 0;
		var topicIsNewOffset: Number = 1;
		var topicIndexOffset: Number = 2;
		
		TopicList.ClearList();
		
		for (var i: Number = 0; i < arguments.length - 1; i += topicDataStride) {
			var topicData: Object = {text: arguments[i + topicTextOffset], topicIsNew: arguments[i + topicIsNewOffset], topicIndex: arguments[i + topicIndexOffset]};
			TopicList.entryList.push(topicData);
		}
		if (arguments[arguments.length - 1] != -1) {
			// Select last topic entry if valid
			TopicList.SetSelectedTopic(arguments[arguments.length - 1]);
		}
		
		TopicList.InvalidateData();
	}

	function DoShowDialogueList(abNewList, abHideExitButton)
	{
		if (eMenuState == DialogueMenu.TOPIC_CLICKED || (eMenuState == DialogueMenu.SHOW_GREETING && TopicList.entryList.length > 0)) {
			ShowDialogueList(abNewList, abNewList && eMenuState == DialogueMenu.TOPIC_CLICKED);
		}
		ExitButton._visible = !abHideExitButton;
	}

	function ShowDialogueList(abSlideAnim, abCopyVisible)
	{
		TopicListHolder._visible = true;
		TopicListHolder.gotoAndPlay(abSlideAnim ? "slideListIn" : "fadeListIn");
		eMenuState = DialogueMenu.TRANSITIONING;
		TopicListHolder.TextCopy_mc._visible = abCopyVisible;
		TopicListHolder.PanelCopy_mc._visible = abCopyVisible;
	}

	function onItemSelect(event)
	{
		if (bAllowProgress && event.keyboardOrMouse != 0) 
		{
			if (eMenuState == DialogueMenu.TOPIC_LIST_SHOWN) {
				onSelectionClick();
			}
			else if (eMenuState == DialogueMenu.TOPIC_CLICKED || eMenuState == DialogueMenu.SHOW_GREETING) {
				SkipText();
			}
			bAllowProgress = false;
		}
	}

	function SkipText()
	{
		if (bAllowProgress) {
			GameDelegate.call("SkipText", []);
			bAllowProgress = false;
		}
	}

	function onMouseDown()
	{
		++DialogueMenu.iMouseDownExecutionCount;
		if (DialogueMenu.iMouseDownExecutionCount % 2 != 0) {
			onItemSelect();
		}
	}

	function onCancelPress()
	{
		if (eMenuState == DialogueMenu.SHOW_GREETING) {
			SkipText();
			return;
		}
		StartHideMenu();
	}

	function StartHideMenu()
	{
		SubtitleText._visible = false;
		bFadedIn = false;
		SpeakerName.SetText(" ");
		ExitButton._visible = false;
		_parent.gotoAndPlay("startFadeOut");
		gfx.io.GameDelegate.call("CloseMenu", []);
	}

	function playListUpAnim(aEvent)
	{
		if (aEvent.scrollChanged == true) {
			aEvent.target._parent.gotoAndPlay("moveUp");
		}
	}

	function playListDownAnim(aEvent)
	{
		if (aEvent.scrollChanged == true) {
			aEvent.target._parent.gotoAndPlay("moveDown");
		}
	}

	function onSelectionClick()
	{
		if (eMenuState == DialogueMenu.TOPIC_LIST_SHOWN) {
			eMenuState = DialogueMenu.TOPIC_CLICKED;
		}
		if (TopicList.scrollPosition != TopicList.selectedIndex) {
			TopicList.RestoreScrollPosition(TopicList.selectedIndex, true);
			TopicList.UpdateList();
		}
		TopicListHolder.gotoAndPlay("topicClicked");
		TopicListHolder.TextCopy_mc._visible = true;
		TopicListHolder.TextCopy_mc.textField.SetText(TopicListHolder.List_mc.selectedEntry.text);
		var textFieldyOffset: Number = TopicListHolder.TextCopy_mc._y - TopicListHolder.List_mc._y - TopicListHolder.List_mc.Entry4._y;
		TopicListHolder.TextCopy_mc.textField._y = 6.25 - textFieldyOffset;
		GameDelegate.call("TopicClicked", [TopicList.selectedEntry.topicIndex]);
	}

	function onFadeOutCompletion()
	{
		GameDelegate.call("FadeDone", []);
	}

}
