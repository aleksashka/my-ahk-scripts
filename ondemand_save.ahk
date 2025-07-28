#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

MsgBox,
(
^+s - Start screenshoting
^+e - End screenshoting
^+r - Reload script
)

DelayS_01S := 1
DelayS_05S := 5
DelayS_01M := 60
DelayS_05M := DelayS_01M * 5
DelayS_10M := DelayS_01M * 10

DelayAfterDone := DelayS_05S

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ctrl+Shift+S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
^+s::
SIGNAL_PREFIX := "tm_page_done"
SIGNAL_SUFFIX := ".txt"
TITLE_PREFIX := "Page "

FileReadLine, DownloadFolder, %A_ScriptDir%\ahk_download_folder.txt, 1
DeleteFilesByPrefixSuffix(DownloadFolder, SIGNAL_PREFIX, "*" . SIGNAL_SUFFIX)

text = Make sure FF saves as Web Page, complete`n`n
text .= "Set download to:`n" . DownloadFolder
MsgBox, %text%

InputBox, Var, AHK, Current page:
if (Var = "") {
    return
} else {
    Current_Page := Var * 1
}

StopScript := 0
text := "1. Open next/previous page (not the needed one)`n"
text .= "2. Click OK below`n"
text .= "3. Press < or > arrow to get to the needed page`n"
text .= "(thus changing URL for TM to start working)"
MsgBox, , % TITLE_PREFIX . Current_Page, %text%

stopReasonMsg := "Done on StopScript = 1"
Loop
{
    title_text := TITLE_PREFIX . Current_Page
    Sleep, 2000
    ; Wait for Tampermonkey signal file
    if (!WaitForSignal(SIGNAL_PREFIX . SIGNAL_SUFFIX, title_text))
    {
        stopReasonMsg := "Timed out waiting for signal from TM!"
        break
    }
    ; Noticed Tampermonkey signal
    text := "Got signal. Saving in " . DelayAfterDone . " second(s)"
    MsgBox, , %title_text%, %text%, %DelayAfterDone%
    Prefix := Format("{:04}", Current_Page) . "_"
    Save_Page_with_Prefix(Prefix)
    if (!WaitForFile(title_text, Prefix, "*.htm")){
        stopReasonMsg := "Timed out waiting for an HTML file: " . Prefix . "*.htm"
        break
    }
    Sleep, 2000
    Send {Right}
    Current_Page++
} Until StopScript = 1

MsgBox, %stopReasonMsg%
return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ctrl+Shift+E
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
^+e::
StopScript := 1
return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ctrl+Shift+R
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
^+r::
Reload
Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
MsgBox,, Oops, The script could not be reloaded
return

WaitForFile(Title, Prefix, Suffix:= "*.html", TimeoutSec:=900, CheckInterval:=5) {
    global DownloadFolder
    pattern := DownloadFolder . "\" . Prefix . Suffix
    elapsed := 0

    Loop {
        If FileExist(pattern)
            return true
        text := "Waiting for the " . Prefix . Suffix . " to appear in`n`n"
        text .= DownloadFolder . "`n`n"
        text .= "Elapsed " . elapsed . " of " . TimeoutSec . " second(s)"
        MsgBox, , %Title%, %text%, %CheckInterval%
        elapsed += CheckInterval
        if (elapsed >= TimeoutSec)
            return false
    }
}

WaitForSignal(FileName, Title, Timeout := 180)
{
    global DownloadFolder
    SignalFile := DownloadFolder . "\" . FileName
    CheckInterval := 2
    Elapsed := 0

    Loop
    {
        Elapsed += CheckInterval
        text := "Waiting for TM signal (" . Elapsed . " of " . Timeout . ")..."
        MsgBox, , %Title%, %text%, %CheckInterval%

        if FileExist(SignalFile)
        {
            FileDelete, %SignalFile%
            return true  ; Signal received
        }

        if (Elapsed >= Timeout)
        {
            return false  ; Timed out
        }
    }
}

Save_Page_with_Prefix(PREFIX, WAIT:=1000) {
    SendInput ^s
    Sleep, WAIT
    Send {Home}
    Sleep, WAIT
    Send %PREFIX%
    Sleep, WAIT
    Send {Enter}
    Sleep, WAIT * 1
}

DeleteFilesByPrefixSuffix(DownloadFolder, Prefix, Suffix:="*.txt") {
    ; Create the search pattern
    SearchPattern := DownloadFolder . "\" . Prefix . Suffix

    ; Loop through all files in the folder that match the prefix
    Loop, Files, %SearchPattern%
    {
        ; Delete the current file
        FileDelete, %A_LoopFileFullPath%
    }
}