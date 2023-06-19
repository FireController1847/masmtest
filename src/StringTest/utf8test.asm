INCLUDELIB kernel32.lib
INCLUDE winutil.inc

; Prototypes
MultiByteToWideChar PROTO

.DATA
ALIGN 16
TestString_LEN  EQU     40
TestString      BYTE    54h, 68h, 69h, 73h, 20h, 69h, 73h, 20h, 61h, 20h, 74h, 65h, 73h, 74h, 20h, 73h
                BYTE    74h, 72h, 69h, 6eh, 67h, 20h, 77h, 72h, 69h, 74h, 74h, 65h, 6eh, 20h, 69h, 6eh
                BYTE    20h, 55h, 54h, 46h, 2dh, 38h, 2eh, 00h
TestStringW     WORD    TestString_LEN * 2 DUP (?)

.CODE
main PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 30h    ; 20h for shadow space, 10h for 2 stack args
    
    ; Initialize console
    CALL InitConsole

    M_UTF8_TO_UTF16LE TestString, TestStringW, TestString_LEN
    M_WRITECONSOLE TestStringW, TestString_LEN
    M_WRITECONSOLE TextNewline, TextNewline_LEN

    ; Exit
    MOV RCX, 0
    CALL PauseAndExit

    ; Epilog (future proofing)
    ADD RSP, 30h
    MOV RSP, RBP
    POP RBP
    RET
main ENDP
END