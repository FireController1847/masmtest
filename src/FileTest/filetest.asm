INCLUDELIB kernel32.lib
INCLUDE winstruct.inc
INCLUDE winutil.inc

; Prototypes
GetFileAttributesW PROTO
GetLastError PROTO

.DATA
; Strings
; TODO: Variable is being overwritten by a call to M_READCONSOLE. Likely an internal issue.
;       I suspect it has to do with buffer overrun. More investigation is needed.
TextInvalidName     WORD    54h, 68h, 65h, 20h, 66h, 69h, 6Ch, 65h, 6Eh, 61h, 6Dh, 65h, 2Ch, 20h, 64h, 69h
                    WORD    72h, 65h, 63h, 74h, 6Fh, 72h, 79h, 20h, 6Eh, 61h, 6Dh, 65h, 2Ch, 20h, 6Fh, 72h
                    WORD    20h, 76h, 6Fh, 6Ch, 75h, 6Dh, 65h, 20h, 6Ch, 61h, 62h, 65h, 6Ch, 20h, 73h, 79h
                    WORD    6Eh, 74h, 61h, 78h, 20h, 69h, 73h, 20h, 69h, 6Eh, 63h, 6Fh, 72h, 72h, 65h, 63h
                    WORD    74h, 2Eh, 0Dh, 0Ah, 00h
TextPrompt          WORD    45h, 6Eh, 74h, 65h, 72h, 20h, 66h, 69h, 6Ch, 65h, 6Eh, 61h, 6Dh, 65h, 3Ah, 20h  ; Enter filename: 
TextTestfilePath    WORD    260 DUP (?)

.CODE
M_COPYSTR MACRO MEM_FROM, MEM_TO
    LOCAL m_copystr
    MOV RCX, 0
m_copystr::
    LEA R8, MEM_FROM
    MOV DX, [R8 + RCX]
    LEA R8, MEM_TO
    MOV [R8 + RCX], DX
    INC RCX
    CMP DX, 0
    JNZ m_copystr
ENDM

InvalidFilePath PROC
    XOR RCX, RCX
    CALL GetLastError
    CMP RAX, 7Bh    ; ERROR_INVALID_NAME 7Bh
    JNE p_unknown_error
p_invalid_file_name::
    M_WRITECONSOLE TextInvalidName, 69
p_unknown_error::
    CALL PauseAndExit
InvalidFilePath ENDP

main PROC
    CALL InitConsole
    M_WRITECONSOLE TextPrompt, LENGTHOF TextPrompt
    M_READCONSOLE
    M_COPYSTR StdInBuffer, TextTestfilePath
    LEA RCX, TextTestfilePath
    ; TODO: This always fails with invalid path. Need to investigate why.
    CALL GetFileAttributesW
    CMP EAX, -1 ; INVALID_FILE_ATTRIBUTES (0xFFFFFFFF)
    JNE SkipInvalidFilePath
    CALL InvalidFilePath
SkipInvalidFilePath:
    CALL ExitProcess
main ENDP
END