scriptName McmRecorder_Action_MenuOption hidden

bool function IsActionType(int actionInfo) global
    return (JMap.hasKey(actionInfo, "choose") || JMap.hasKey(actionInfo, "chooseIndex")) && JMap.hasKey(actionInfo, "option")
endFunction

function Play(int actionInfo) global
    if McmRecorder_Player.IsCurrentRecordingCanceled() || McmRecorder_Action_Option.ShouldSkipOption()
        return
    endIf

    string modName = McmRecorder_Player.GetCurrentPlayingRecordingModName()
    string pageName = McmRecorder_Player.GetCurrentPlayingRecordingModPageName()
    string menuOptionName = JMap.getStr(actionInfo, "choose")
    int menuOptionIndex = JMap.getInt(actionInfo, "chooseIndex")
    string selector = JMap.getStr(actionInfo, "option")

    if JMap.hasKey(actionInfo, "choose")
        McmRecorder_Logging.ConsoleOut("[Play Action] choose '" + menuOptionName + "' from '" + selector + "'")
    elseIf JMap.hasKey(actionInfo, "chooseIndex")
        McmRecorder_Logging.ConsoleOut("[Play Action] choose option number " + (menuOptionIndex + 1) + " from '" + selector + "'")
    endIf

    SKI_ConfigBase mcmMenu = McmRecorder_ModConfigurationMenu.GetMenu(modName)
    if ! mcmMenu
        McmRecorder_Player.McmMenuNotFound(actionInfo, modName)
        return
    endIf

    int option = McmRecorder_Action_Option.GetOption(mcmMenu, modName, pageName, "menu", selector)
    if ! option
        McmRecorder_Player.OptionNotFound(actionInfo, modName, pageName, "menu '" + selector + "'")
        return
    endIf

    if JMap.hasKey(actionInfo, "choose")
        PerformAction_ByName(mcmMenu, option, menuOptionName)
    elseIf JMap.hasKey(actionInfo, "chooseIndex")
        PerformAction_ByIndex(mcmMenu, option, menuOptionIndex)
    endIf
endFunction

function PerformAction_ByName(SKI_ConfigBase mcmMenu, int option, string menuOptionName) global
    int optionId = JMap.getInt(option, "id")
    string stateName = JMap.getStr(option, "state")
    if stateName
        string previousState = mcmMenu.GetState()
        mcmMenu.GotoState(stateName)
        mcmMenu.OnMenuOpenST()
        mcmMenu.GotoState(previousState)
        string[] menuOptions = McmRecorder_McmFields.GetLatestMenuOptions(mcmMenu) ; TODO - find a way to make this work with MCM Helper
        int itemIndex = menuOptions.Find(menuOptionName)
        if itemIndex == -1
            McmRecorder_UI.MessageBox("Could not find " + menuOptionName + " menu item. Available options: " + menuOptions)
        else
            mcmMenu.OnMenuAcceptST(itemIndex)
        endIf
    else
        mcmMenu.OnOptionMenuOpen(optionId)
        string[] menuOptions = McmRecorder_McmFields.GetLatestMenuOptions(mcmMenu)
        int itemIndex = menuOptions.Find(menuOptionName)
        if itemIndex == -1
            McmRecorder_UI.MessageBox("Could not find " + menuOptionName + " menu item. Available options: " + menuOptions)
        else
            mcmMenu.OnOptionMenuAccept(optionId, itemIndex)
        endIf
    endIf
endFunction

function PerformAction_ByIndex(SKI_ConfigBase mcmMenu, int option, int menuOptionIndex) global
    int optionId = JMap.getInt(option, "id")
    string stateName = JMap.getStr(option, "state")
    if stateName
        string previousState = mcmMenu.GetState()
        mcmMenu.GotoState(stateName)
        mcmMenu.OnMenuAcceptST(menuOptionIndex)
        mcmMenu.GotoState(previousState)
    else
        mcmMenu.OnOptionMenuAccept(optionId, menuOptionIndex)
    endIf
endFunction
