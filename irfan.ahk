#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

MsgBox,
(
^+s - Start screenshoting (Ctrl+F11)
^+e - End screenshoting
^+r - Reload script
)

^+s::
DelaySeconds = 5

InputBox, Var, AHK, Pages to save:
if (Var = "") {
    return
} else {
    PagesToSave := Var * 1
}

DelayMSec := DelaySeconds * 1000
StopScript := 0

Sleep, DelayMSec
Loop {
    Sleep, 1000
    Send ^{F11}
    Sleep, 100
    Send {Right}
    ; Send {PgDn}
    if (--PagesToSave = 0) {
        return
    }
    text := "Pages left: " . PagesToSave . "`n" . TimeLeft(PagesToSave * DelaySeconds)
    MsgBox, , % "Pages left: " . PagesToSave, %text%, %DelaySeconds%
} Until StopScript = 1
return


^+e::
StopScript := 1
return

^+r::
Reload
Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
MsgBox,, Oops, The script could not be reloaded
return


TimeLeft(seconds) {
    hours := Floor(seconds / 3600)
    minutes := Floor(Mod(seconds, 3600) / 60)
    result := "Time left: "

    if (hours > 0)
        result .= hours . " hour" . (hours = 1 ? "" : "s") . " "

    if (minutes > 0 || hours = 0)
        result .= minutes . " minute" . (minutes = 1 ? "" : "s")

    return result
}

