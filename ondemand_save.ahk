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
DelayAfterNext := DelayS_05S * 2

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

WaitUntilFolderSizeStable(Title, Prefix := "", CheckInterval := 5, StableDuration := 15)
{
    lastSize := 0
    stableTime := 0
    global DownloadFolder
    pattern := DownloadFolder . "\" . Prefix . "*_files"

    Loop
    {
        formattedLastSize := FormatNumberWithCommas(lastSize)
        text := "Waiting for the stable non-zero size of " . Prefix . "*_files`n"
        text .= formattedLastSize . " (" . stableTime . " of " . StableDuration . " s)`n"
        MsgBox, , %Title%, %text%, %CheckInterval%

        totalSize := 0
        Loop, Files, %pattern%, D  ; D = directories only
        {
            folderPath := A_LoopFileFullPath
            Loop, Files, %folderPath%\*.*, FR
            {
                totalSize += A_LoopFileSize
            }
        }
        ;MsgBox, % "Total size of " . pattern . " is " . totalSize . " bytes"

        ; Work only on positive
        if (totalSize = 0)
        {
            continue
        }

        ; Compare to previous size
        if (totalSize = lastSize)
        {
            stableTime += CheckInterval
        }
        else
        {
            stableTime := 0
            lastSize := totalSize
        }

        ; Stop if size is stable long enough
        if (stableTime >= StableDuration)
            break
    }

    return totalSize  ; Return the final size if needed
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

InputBox, Var, AHK, Pages to save:
if (Var = "") {
    return
} else {
    LastPageToSave := Var * 1 + Current_Page
}

StopScript := 0
text := "Sending TM signal in " . DelayS_01S . " + 2 second(s)"
MsgBox, , %pages_left_text%, %text%, %DelayS_01S%

stopReasonMsg := "Done on StopScript = 1"
Loop
{
    if (tooManySameTitles())
    {
        stopReasonMsg := "Stop on same number of titles: " . sameTitleMaxCount
        break
    }
    pages_left := LastPageToSave - Current_Page
    pages_left_text := "Pages left: " . pages_left
    Sleep, 2000
    ; Signal Tampermonkey to press buttons if any
    SendInput ^+z
    ; Wait for Tampermonkey signal file
    if (WaitForSignal(PAGE_DONE_SIGNAL, pages_left_text))
    {
        ; Noticed Tampermonkey signal
        ; Save the page
        text := "Got signal back! Saving in " . DelayAfterDone . " second(s)"
        MsgBox, , %pages_left_text%, %text%, %DelayAfterDone%
        Prefix := Format("{:04}", Current_Page) . "_"
        Chrome_Save_Page_with_Prefix(Prefix)
        if (++Current_Page >= LastPageToSave) {
            stopReasonMsg := "Done on LastPageToSave"
            break
        }
        WaitUntilFolderSizeStable(pages_left_text, Prefix)
        Sleep, 2000
        Send {Right}
        text := "Waiting after ""Next"" and sending TM a signal in "
        text .= DelayAfterNext . " + 2 second(s)"
        MsgBox, , %pages_left_text%, %text%, %DelayAfterNext%
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
