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

; Ctrl+Shift+S
^+s::
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

DelaySeconds := 5
DelayAfterSave := DelaySeconds * 12
DelayAfterNext := DelaySeconds * 2
StopScript := 0

Loop {
    pages_left := LastPageToSave - Current_Page
    pages_left_text := "Pages left: " . pages_left

    MsgBox, , %pages_left_text%, PgDn and Save in %DelaySeconds% second(s), %DelaySeconds%
    Wait_and_Press_PgDn_Multiple_Times()
    Prefix := Format("{:04}", Current_Page) . "_"
    Chrome_Save_Page_with_Prefix(Prefix)
    if (++Current_Page >= LastPageToSave) {
        return
    }
    MsgBox, , %pages_left_text%, Next page in %DelayAfterSave% second(s), %DelayAfterSave%
    Sleep, 2000
    Send {Right}
    MsgBox, , %pages_left_text%, Wait loading for %DelayAfterNext% second(s), %DelayAfterNext%
} Until StopScript = 1

MsgBox, Done
return

;Sleep_Random(DelaySeconds, PagesToSave){
;    R_MIN := ( DelaySeconds + 0 ) * 1000
;    R_MAX := ( DelaySeconds + 9 ) * 1000
;    Random, RAND, R_MIN, R_MAX
;    Seconds := ROUND(RAND/1000)
;    MsgBox, , Wait: %Seconds% s, Pages left: %PagesToSave%, %Seconds%
;    Sleep, 300
;}

^+e::
StopScript := 1
return

^+r::
Reload
Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
MsgBox,, Oops, The script could not be reloaded
return
