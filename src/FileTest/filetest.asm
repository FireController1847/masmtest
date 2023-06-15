INCLUDELIB kernel32.lib
INCLUDE winutil.inc

.DATA


.CODE
main PROC
    CALL InitConsole
    CALL PauseAndExit
main ENDP
END