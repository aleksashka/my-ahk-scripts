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

FileReadLine, DownloadFolder, %A_ScriptDir%\ahk_download_folder.txt, 1
PAGE_DONE_SIGNAL := "tm_page_done.txt"

sameTitleCount := 0  ; Counter to track consecutive same window title
sameTitleMaxCount := 3  ; Stop if this number of titles is same in a row
previousTitle := ""  ; Store the previous window title
title_prefix := "Page "

SignalFile := DownloadFolder . "\" . PAGE_DONE_SIGNAL
if FileExist(SignalFile)
{
    FileDelete, %SignalFile%
}

DelayS_01S := 1
DelayS_05S := 5
DelayS_01M := 60
DelayS_05M := DelayS_01M * 5
DelayS_10M := DelayS_01M * 10

DelayAfterDone := DelayS_05S

tooManySameTitles() {
    global sameTitleCount, sameTitleMaxCount, previousTitle

    WinGetTitle, currentTitle, A  ; Get the current active window title
    if (currentTitle = previousTitle)
    {
        sameTitleCount++  ; Increment count if title is the same
    }
    else
    {
        sameTitleCount := 0  ; Reset count if window title changes
    }
    previousTitle := currentTitle  ; Save current title

    return sameTitleCount >= sameTitleMaxCount
}
FormatNumberWithCommas(n) {
    str := ""
    n := RegExReplace(n, "[^\d]")  ; Strip non-digits
    Loop
    {
        if (StrLen(n) <= 3)
        {
            str := n . (str != "" ? "," . str : "")
            break
        }
        str := SubStr(n, -2) . (str != "" ? "," . str : "")
        n := SubStr(n, 1, -3)
    }
    return str
}

WaitForFile(Title, Prefix, Suffix:= "*.html", TimeoutSec:=900, CheckInterval:=5) {
    global DownloadFolder
    pattern := DownloadFolder . "\" . Prefix . Suffix
    elapsed := 0

    Loop {
        If FileExist(pattern)
            return true
        text := "Waiting for the " . Prefix . Suffix . " to appear in`n"
        text .= DownloadFolder . "`n"
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

Chrome_Save_Page_with_Prefix(PREFIX, WAIT:=1000) {
    SendInput ^s
    Sleep, WAIT
    Send {Home}
    Sleep, WAIT
    Send %PREFIX%
    Sleep, WAIT
    Send {Enter}
    Sleep, WAIT * 1
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ctrl+Shift+S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
^+s::
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
text := "Open next/previous page (not the needed one), then click OK below and`n"
text .= "press < or > button to get to the needed page thus changing URL for TM to notice"
MsgBox, , % title_prefix . Current_Page, %text%

stopReasonMsg := "Done on StopScript = 1"
Loop
{
    if (tooManySameTitles())
    {
        stopReasonMsg := "Stop on same number of titles: " . sameTitleMaxCount
        break
    }
    title_text := title_prefix . Current_Page
    Sleep, 2000
    ; Wait for Tampermonkey signal file
    if (WaitForSignal(PAGE_DONE_SIGNAL, title_text))
    {
        ; Noticed Tampermonkey signal
        text := "Got signal. Saving in " . DelayAfterDone . " second(s)"
        MsgBox, , %title_text%, %text%, %DelayAfterDone%
        Prefix := Format("{:04}", Current_Page) . "_"
        Chrome_Save_Page_with_Prefix(Prefix)
        if (!WaitForFile(title_text, Prefix, "*.htm")){
            stopReasonMsg := "Timed out waiting for an HTML file: " . Prefix . "*.htm"
            break
        }
        Sleep, 2000
        Send {Right}
        Current_Page++
    }
    else
    {
        stopReasonMsg := "Timed out waiting for signal!"
        break
    }
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
