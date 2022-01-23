scriptName McmRecorder_RecordingInfo hidden

int function Get(string recordingName) global
    return McmRecorder_RecordingFiles.GetRecordingInfo(recordingName)
endFunction

; TODO remove the recordingName parameter
function Save(string recordingName, int recordingInfo) global
    McmRecorder_RecordingFiles.SaveRecordingInfoFile(recordingName, recordingInfo)
endFunction

bool function IsAutorun(int recordingInfo) global
    return JMap.getStr(recordingInfo, "autorun") == "true"
endFunction

bool function IsVrGesture(int recordingInfo) global
    return JMap.getStr(recordingInfo, "gesture") == "true"
endFunction

bool function IsHidden(int recordingInfo) global
    return JMap.getStr(recordingInfo, "hidden") == "true"
endFunction

bool function SetIsVrGesture(int recordingInfo, bool enabled = true) global
    if enabled
        JMap.setStr(recordingInfo, "gesture", "true")
    else
        JMap.removeKey(recordingInfo, "gesture")
    endIf
    Save(GetName(recordingInfo), recordingInfo)
endFunction

string function GetName(int recordingInfo) global
    return JMap.getStr(recordingInfo, "name")
endFunction

; TODO support replacements like $STEP_COUNT$ or something.
string function GetWelcomeMessage(int recordingInfo) global
    return JMap.getStr(recordingInfo, "welcome")
endFunction

string function GetCompleteMessage(int recordingInfo) global
    return JMap.getStr(recordingInfo, "complete")
endFunction

int function GetTotalActionCount(int recordingInfo) global
    string recordingName = GetName(recordingInfo)
    int steps = McmRecorder_RecordingFiles.GetAllStepsForRecording(recordingName)
    string[] stepNames = JMap.allKeysPArray(steps)
    int stepCount = JMap.count(steps)
    int actionCount = 0
    int i = 0
    while i < stepCount
        int step = JMap.getObj(steps, stepNames[i])
        actionCount += JArray.count(step) ; <--- this is how many actions there are
        i += 1
    endWhile
    return actionCount
endFunction

string function GetDescriptionText(int recordingInfo) global
    string recordingName = GetName(recordingInfo)
    string[] stepNames = McmRecorder_RecordingFiles.GetRecordingStepFilenames(recordingName)
    string recordingDescription = recordingName
    recordingDescription += "\nSteps: " + stepNames.Length
    return recordingDescription
endFunction
