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

DelayS_01S := 1
DelayS_05S := 5
DelayS_01M := 60
DelayS_05M := DelayS_01M * 5
DelayS_10M := DelayS_01M * 10

DelayAfterDone := DelayS_05S
DelayAfterSave := DelayS_05S * 3
DelayAfterNext := DelayS_05S * 2

WaitForSignal(FileName, CheckInterval := 500, Timeout := 10000)
{
    global DownloadFolder
    SignalFile := DownloadFolder . "\" . FileName
    ;MsgBox, % SignalFile . " " . CheckInterval . " " . Timeout
    Elapsed := 0

    Loop
    {
        ; TODO Wait using MsgBox
        Sleep, %CheckInterval%
        Elapsed += CheckInterval

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

Wait_and_Press_PgDn_Multiple_Times(NUM:=30, WAIT:=1000) {
    Loop %NUM%
    {
        Sleep, WAIT
        Send {PgDn}
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

InputBox, Var, AHK, Pages to save:
if (Var = "") {
    return
} else {
    LastPageToSave := Var * 1 + Current_Page
}

StopScript := 0
MsgBox, , %pages_left_text%, Sending TM signal in %DelayS_05S% second(s), %DelayS_05S%
Loop
{
    pages_left := LastPageToSave - Current_Page
    pages_left_text := "Pages left: " . pages_left
    ; Signal Tampermonkey to press buttons if any
    SendInput ^+z
    ; Wait for Tampermonkey signal file
    if (WaitForSignal(PAGE_DONE_SIGNAL, DelayS_01S * 1000, DelayS_05M * 1000))
    {
        ; Noticed Tampermonkey signal
        ; Save the page
        text := "Got signal back! Saving in " . DelayAfterDone . " second(s)"
        MsgBox, , %pages_left_text%, %text%, %DelayAfterDone%
        Prefix := Format("{:04}", Current_Page) . "_"
        Chrome_Save_Page_with_Prefix(Prefix)
        if (++Current_Page >= LastPageToSave) {
            MsgBox, Done on LastPageToSave
            return
        }
        text := "Waiting after ""Save"" for  " . DelayAfterSave . " + 2 second(s)"
        MsgBox, , %pages_left_text%, %text%, %DelayAfterSave%
        Sleep, 2000
        Send {Right}
        text := "Waiting after ""Next"" for  " . DelayAfterNext . " second(s)"
        MsgBox, , %pages_left_text%, %text%, %DelayAfterNext%
    }
    else
    {
        MsgBox, Timed out waiting for signal.
    }
} Until StopScript = 1

MsgBox, Done on StopScript = 1
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
