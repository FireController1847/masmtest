INCLUDELIB kernel32.lib
INCLUDE winstruct.inc
INCLUDE winutil.inc

; Prototypes
GetFileAttributesW PROTO
CreateFileW PROTO
GetFileSizeEx PROTO
GetLastError PROTO

.DATA
ALIGN 16

; Strings
TextNewline             WORD    0Dh, 0Ah, 00h   ; CRLF
TextErrorCode0002       WORD    0Dh, 0Ah, 54h, 68h, 65h, 20h, 73h, 79h, 73h, 74h, 65h, 6Dh, 20h, 63h, 61h, 6Eh
                        WORD    6Eh, 6Fh, 74h, 20h, 66h, 69h, 6Eh, 64h, 20h, 74h, 68h, 65h, 20h, 66h, 69h, 6Ch
                        WORD    65h, 20h, 73h, 70h, 65h, 63h, 69h, 66h, 69h, 65h, 64h, 2Eh, 00h       ; The system cannot find the file specified.
TextErrorCode0002_LEN   EQU     45
TextInternalError       WORD    0Dh, 0Ah, 41h, 6Eh, 20h, 69h, 6Eh, 74h, 65h, 72h, 6Eh, 61h, 6Ch, 20h, 65h, 72h
                        WORD    72h, 6Fh, 72h, 20h, 68h, 61h, 73h, 20h, 6Fh, 63h, 63h, 75h, 72h, 72h, 65h, 64h
                        WORD    20h, 61h, 6Eh, 64h, 20h, 74h, 68h, 65h, 20h, 70h, 72h, 6Fh, 67h, 72h, 61h, 6Dh
                        WORD    20h, 77h, 69h, 6Ch, 6Ch, 20h, 6Eh, 6Fh, 77h, 20h, 63h, 6Ch, 6Fh, 73h, 65h, 2Eh
                        WORD    20h, 28h, 30h, 78h, 30h, 30h, 30h, 30h, 29h, 0Dh, 0Ah, 00h
TextInternalError_LEN   EQU     74
TextPrompt              WORD    45h, 6Eh, 74h, 65h, 72h, 20h, 66h, 69h, 6Ch, 65h, 6Eh, 61h, 6Dh, 65h, 3Ah, 20h  ; Enter filename: 
TextTestfilePath        WORD    260 DUP (?)
UnicodeNumbers          WORD    30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h

; Handles
fileAttributes  QWORD   ?
hFile           QWORD   ?

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

M_REMOVECRLF MACRO PTR_STR, STR_CHARS
    LEA RCX, PTR_STR
    MOV RDX, QWORD PTR STR_CHARS
    ADD RCX, RDX
    ADD RCX, RDX
    SUB RCX, DWORD
    MOV QWORD PTR [RCX], 00h
ENDM

; Hex to Unicode
HexToUnicode PROC
    XOR RAX, RAX
    MOV RDX, 4
p_loop::
    MOV R8, RCX
    CMP RDX, 4
    JE p_shr_loop_exit
    MOV R9, 4
    SUB R9, RDX
p_shr_loop::
    SHR R8, 4
    DEC R9
    JNZ p_shr_loop
p_shr_loop_exit::
    AND R8, 1111b
    LEA R9, UnicodeNumbers
    ADD R9, R8
    ADD R9, R8
    MOV AX, WORD PTR [R9]
    DEC RDX
    JZ p_shl_skip
    SHL RAX, 16
p_shl_skip:
    JNZ p_loop
    SHL RAX, 8
    RET
HexToUnicode ENDP

InternalError PROC
    ; Get last error
    XOR RCX, RCX
    SUB RSP, 20h
    CALL GetLastError
    ADD RSP, 20h

    ; Convert to Unicode
    MOV RCX, RAX
    PUSH RAX
    CALL HexToUnicode

    ; Update error string
    LEA RCX, TextInternalError
    ADD RCX, TextInternalError_LEN * 2
    SUB RCX, 6 * 2 + 1
    MOV [RCX], RAX

    ; Write error
    M_WRITECONSOLE TextInternalError, TextInternalError_LEN
    POP RAX

    ; Print known errors
    CMP RAX, 02h
    JE p_file_not_found
    JMP p_exit
p_file_not_found::
    M_WRITECONSOLE TextErrorCode0002, TextErrorCode0002_LEN
p_exit::
    ; Exit
    CALL PauseAndExit
InternalError ENDP


main PROC
    LOCAL CharsWritten: QWORD
    CALL InitConsole

    ; Prompt for filename
    M_WRITECONSOLE TextPrompt, LENGTHOF TextPrompt
    M_READCONSOLE
    M_COPYSTR StdInBuffer, TextTestfilePath
    MOV ECX, StdInCharsWritten
    MOV CharsWritten, RCX
    M_REMOVECRLF TextTestfilePath, StdInCharsWritten

    ; Get attributes
    LEA RCX, TextTestfilePath
    SUB RSP, 20h
    CALL GetFileAttributesW
    ADD RSP, 20h
    CMP EAX, -1 ; INVALID_FILE_ATTRIBUTES (0xFFFFFFFF)
    ; TODO: Instead of just erroring, re-prompt the user for a valid file.
    JNE p_skip_invalid_file_path
    CALL InternalError
p_skip_invalid_file_path::
    MOV fileAttributes, RAX
    CALL ClearRegisters
    M_WRITECONSOLE TextTestfilePath, CharsWritten
    M_WRITECONSOLE TextNewline, 3

    ; Open the file for GENERIC_READ
    CALL ClearRegisters
    LEA RCX, TextTestfilePath
    MOV RDX, 80000000h  ; GENERIC_READ
    MOV R8, 00000001h   ; FILE_SHARE_READ
    MOV R9, 0h          ; NULL
    SUB RSP, 50h
    PUSH 0h             ; NULL
    PUSH 80h            ; FILE_ATTRIBUTE_NORMAL
    PUSH 3              ; OPEN_EXISTING
    CALL CreateFileW
    ADD RSP, 50h
    CMP EAX, -1
    JNE p_skip_invalid_create_file
    CALL InternalError
p_skip_invalid_create_file::

    ; Exit process
    CALL ClearRegisters
    CALL PauseAndExit
main ENDP
END
