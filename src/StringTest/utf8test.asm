INCLUDELIB kernel32.lib
INCLUDE winutil.inc

.CODE
main PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h
    
    ; Initialize console
    CALL InitConsole

    ; Exit
    MOV RCX, 0
    CALL PauseAndExit

    ; Epilog (future proofing)
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
    RET
main ENDP
END