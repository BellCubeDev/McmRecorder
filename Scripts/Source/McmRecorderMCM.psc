scriptName McmRecorderMCM extends SKI_ConfigBase
{**PRIVATE** Please do not edit.}

McmRecorder Recorder

int oid_Record
int oid_Stop
int[] oids_Recordings

string[] recordings
bool isPlayingRecording
string currentlyPlayingRecordingName
bool openRunOrPreviewStepsPrompt

bool IsSkyrimVR

event OnConfigInit()
    ModName = "MCM Recorder"
    Recorder = (self as Quest) as McmRecorder
    IsSkyrimVR = Game.GetModByName("SkyrimVR.esm") != 255
endEvent

; event OnConfigOpen()
; endEvent

event OnPageReset(string page)
    if McmRecorder_Recorder.IsRecording()
        oid_Stop = AddTextOption("Currently Recording!", "STOP RECORDING", OPTION_FLAG_NONE)
        AddTextOption(McmRecorder_Recorder.GetCurrentRecordingName(), "", OPTION_FLAG_DISABLED)
    else
        if IsSkyrimVR
            oid_Record = AddTextOption("Click to begin recording:", "BEGIN RECORDING", OPTION_FLAG_NONE)
        else
            oid_Record = AddInputOption("Click to begin recording:", "BEGIN RECORDING", OPTION_FLAG_NONE)
        endIf
        AddEmptyOption()
    endIf
    ListRecordings()
endEvent

function ListRecordings()
    recordings = McmRecorder_RecordingFiles.GetRecordingNames()
    if recordings.Length && ((! McmRecorder_Recorder.IsRecording()) || recordings.Length > 1)
        AddEmptyOption()
        AddEmptyOption()
        AddTextOption("Choose a recording to play:", "", OPTION_FLAG_DISABLED)
        AddEmptyOption()
        oids_Recordings = Utility.CreateIntArray(recordings.Length)
        int i = 0
        while i < recordings.Length
            string recordingName = recordings[i]
            if recordingName != McmRecorder_Recorder.GetCurrentRecordingName()
                string[] stepNames = McmRecorder_RecordingFiles.GetRecordingStepFilenames(recordingName)
                oids_Recordings[i] = AddTextOption("", recordingName, OPTION_FLAG_NONE)
                int recordingInfo = McmRecorder_RecordingFiles.GetRecordingInfo(recordingName)
                string authorText = ""
                if JMap.getStr(recordingInfo, "author")
                    authorText = "by " + JMap.getStr(recordingInfo, "author")
                endIf
                AddTextOption(authorText, JMap.getStr(recordingInfo, "version"), OPTION_FLAG_DISABLED)
            endIf
            i += 1
        endWhile
    endIf
endFunction

event OnOptionSelect(int optionId)
    if IsSkyrimVR && optionId == oid_Record ; SkyrimVR
        if ! McmRecorder_Recorder.IsRecording()
            McmRecorder_Recorder.BeginRecording(GetRandomRecordingName())
            ForcePageReset()
        else
            McmRecorder_Recorder.StopRecording() ; For SkyrimVR these OIDs are the same
            ForcePageReset()
        endIf
    elseIf optionId == oid_Stop
        McmRecorder_Recorder.StopRecording()
        ForcePageReset()
    elseIf oids_Recordings.Find(optionId) > -1
        int recordingIndex = oids_Recordings.Find(optionId)
        string recordingName = recordings[recordingIndex]
        PromptToRunRecordingOrPreviewSteps(recordingName)
    endIf
endEvent

event OnOptionInputAccept(int optionId, string text)
    McmRecorder_Recorder.BeginRecording(text)
    ForcePageReset()
    Debug.MessageBox("Recording Started!\n\nYou can now interact with MCM menus and all interactions will be recorded.\n\nWhen you are finished, return to this page to stop the recording (or quit the game).\n\nRecordings are saved in simple text files inside of Data\\McmRecorder\\ which you can edit to tweak your recording without completely re-recording it :)")
endEvent

event OnOptionInputOpen(int optionId)
    if optionId == oid_Record
        SetInputDialogStartText(GetRandomRecordingName())
    endIf
endEvent

string function GetRandomRecordingName()
    string[] currentTimeParts = StringUtil.Split(Utility.GetCurrentRealTime(), ".")
    return "Recording_" + currentTimeParts[0] + "_" + currentTimeParts[1]
endFunction

event OnMenuOpen(string menuName)
    if menuName == "Journal Menu"
        if isPlayingRecording
            Debug.MessageBox("MCM Recorder " + currentlyPlayingRecordingName + " playback in progress. Opening MCM menu not recommended!")            
        endIf
    endIf
endEvent

; TODO move to the McmRecorder maybe a global script for prompts
function PromptToRunRecordingOrPreviewSteps(string recordingName)
    string recordingDescription = McmRecorder_RecordingFiles.GetRecordingDescription(recordingName)

    bool confirmation = true

    ; The ShowMessage prompt can not be interacted with via SkyrimVR so we simply show a prompt - not a confirmation dialog
    if ! IsSkyrimVR
        confirmation = ShowMessage(recordingDescription + "\n\nClose the MCM to continue\n\nYou will be prompted to play this recording\n\nYou will also be able to preview all recording steps or play individual one\n\nYou will also be given the opportunity to continue the recording\n\nWould you like to continue?", "No", "Yes", "Cancel")
        if confirmation
            Debug.MessageBox("Close the MCM to continue")
        endIf
    endIf

    if confirmation
        UnregisterForMenu("Journal Menu")  
        RegisterForMenu("Journal Menu") ; Track when the menu opens so we can show a mesasge if a recording is playing
        string[] stepNames = McmRecorder_RecordingFiles.GetRecordingStepFilenames(recordingName)
        string text = recordingDescription + "\n"
        int i = 0
        while i < stepNames.Length && i < 11
            if i == 10
                text += "\n- ..."
            else
                text += "\n- " + StringUtil.Substring(stepNames[i], 0, StringUtil.Find(stepNames[i], ".json"))
            endIf
            i += 1
        endWhile
        text += "\n\nWould you like to play this recording?"

        ; Inlined to extract method later
        Recorder.McmRecorder_MessageText.SetName(text)
        int responseId = Recorder.McmRecorder_Message_RunRecordingOrViewSteps.Show()
        string response
        if responseId == 0
            response = "Play Recording"
        elseIf responseId == 1
            response = "View Steps"
        elseIf responseId == 2
            response = "Add to Recording"
        elseIf responseId == 3
            response = "Cancel"
        endIf

        if response == "Play Recording"
            currentlyPlayingRecordingName = recordingName
            isPlayingRecording = true
            McmRecorder_Player.PlayRecording(recordingName)
            currentlyPlayingRecordingName = ""
            isPlayingRecording = false
        elseIf response == "View Steps"
            ShowStepSelectionUI(recordingName, stepNames)
        elseIf response == "Add to Recording"
            McmRecorder_Recorder.ContinueRecording(recordingName)
            Debug.MessageBox("Recording has been restarted!\n\nYou can now interact with MCM menus and all interactions will be recorded.\n\nWhen you are finished, return to the MCM Recorder mod configuration menu to stop the recording (or quit the game).\n\nRecordings are saved in simple text files inside of Data\\McmRecorder\\ which you can edit to tweak your recording without completely re-recording it :)")
        endIf
    endIf
endFunction

function ShowStepSelectionUI(string recordingName, string[] stepNames)
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
    menu.AddEntryItem("[" + recordingName + "]")
    menu.AddEntryItem(" ")

    int i = 0
    while i < stepNames.Length
        string stepName = stepNames[i]
        menu.AddEntryItem(stepName)
        i += 1
    endWhile

    menu.OpenMenu()

    int selection = menu.GetResultInt()

    if selection < 2 ; Go Back
        ; TODO open the previous prompt! This isn't working...
        ; PromptToRunRecordingOrPreviewSteps(recordingName)
    else
        int stepIndex = selection - 2 ; Subtract the top 3 entry items
        string stepName = stepNames[stepIndex]
        McmRecorder_Player.PlayStep(recordingName, stepName)
        Debug.MessageBox("MCM recording " + recordingName + " step " + StringUtil.Substring(stepName, 0, StringUtil.Find(stepName, ".json")) + " has finished playing.")
    endIf
endFunction
