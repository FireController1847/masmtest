INCLUDELIB kernel32.lib

; =========================
; ==       WINUTIL       ==
; =========================
; Updated: 2023-06-19
; Author: FireController#1847
; Copyright: © 2023 - All Rights Reserved.

; Constants
STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11
MAX_PATH EQU 260

; Prototypes
GetStdHandle PROTO
WriteConsoleW PROTO
ReadConsoleW PROTO
SetLastError PROTO
GetLastError PROTO
MultiByteToWideChar PROTO
ExitProcess PROTO

.DATA
ALIGN 16

; Utility
UnicodeNumbers      WORD    30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h

; Strings
TextNewline_LEN         EQU     3   ; CRLF
TextNewline             WORD    0Dh, 0Ah, 00h
TextToExit_LEN          EQU     23  ; Press enter to exit.
TextToExit              WORD    0Dh, 0Ah, 50h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh
                        WORD    20h, 65h, 78h, 69h, 74h, 2Eh, 00h
TextInternalError_LEN   EQU     74  ; An internal error has occurred and the program will now close. (0x0000)
TextInternalError       WORD    0Dh, 0Ah, 41h, 6Eh, 20h, 69h, 6Eh, 74h, 65h, 72h, 6Eh, 61h, 6Ch, 20h, 65h, 72h
                        WORD    72h, 6Fh, 72h, 20h, 68h, 61h, 73h, 20h, 6Fh, 63h, 63h, 75h, 72h, 72h, 65h, 64h
                        WORD    20h, 61h, 6Eh, 64h, 20h, 74h, 68h, 65h, 20h, 70h, 72h, 6Fh, 67h, 72h, 61h, 6Dh
                        WORD    20h, 77h, 69h, 6Ch, 6Ch, 20h, 6Eh, 6Fh, 77h, 20h, 63h, 6Ch, 6Fh, 73h, 65h, 2Eh
                        WORD    20h, 28h, 30h, 78h, 30h, 30h, 30h, 30h, 29h, 0Dh, 0Ah, 00h

; Standard I/O
StdOutHandle        QWORD   ?
StdInHandle         QWORD   ?
StdInBuffer         WORD    MAX_PATH DUP (?)
StdInCharsWritten   DWORD   ?

.CODE
M_WRITECONSOLE MACRO W_STR, W_STRLEN
    MOV RCX, StdOutHandle
    LEA RDX, W_STR
    MOV R8, W_STRLEN
    XOR R9, R9
    MOV QWORD PTR [RSP + 20h], 0
    CALL WriteConsoleW
    CMP RAX, 0
    JZ Crash
ENDM

M_READCONSOLE MACRO
    MOV RCX, StdInHandle
    LEA RDX, StdInBuffer
    MOV R8, LENGTHOF StdInBuffer
    LEA R9, StdInCharsWritten
    MOV QWORD PTR [RSP + 20h], 0
    CALL ReadConsoleW
    CMP RAX, 0
    JZ Crash
ENDM

M_COPYWSTR MACRO MEM_FROM, MEM_TO
    LOCAL m_copywstr
    MOV RCX, 0
    LEA R8, MEM_FROM
    LEA R9, MEM_TO
m_copywstr::
    MOV DX, [R8 + RCX * 2]
    MOV [R9 + RCX * 2], DX
    INC RCX
    CMP DX, 0
    JNZ m_copywstr
ENDM

M_UTF16LE_REMOVECRLF MACRO W_STR, W_STRLEN
    LEA RCX, W_STR
    MOV RDX, QWORD PTR W_STRLEN
    ADD RCX, RDX
    ADD RCX, RDX
    SUB RCX, 4
    MOV DWORD PTR [RCX], 0
ENDM

M_UTF8_TO_UTF16LE MACRO UTF8_STR, UTF16_BUFFER, STRLEN
    MOV RCX, 65001
    MOV RDX, 0
    LEA R8, UTF8_STR
    LEA R9, UTF16_BUFFER
    MOV QWORD PTR [RSP + 20h], R9
    MOV QWORD PTR [RSP + 28h], STRLEN - 1
    MOV R9, STRLEN - 1
    CALL MultiByteToWideChar
ENDM

; Crash Procedure
Crash PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h

    ; Get last error (used for debugging)
    CALL GetLastError

    ; Exit
    MOV RCX, RAX    ; Exit code of last error
    CALL ExitProcess
Crash ENDP

; Initialize Console Procedure
InitConsole PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h

    ; Set last error
    XOR RCX, RCX
    CALL SetLastError

    ; Fetch console handles
    MOV RCX, STD_OUTPUT_HANDLE
    CALL GetStdHandle
    JZ Crash
    MOV StdOutHandle, RAX
    MOV RCX, STD_INPUT_HANDLE
    CALL GetStdHandle
    JZ Crash
    MOV StdInHandle, RAX

    ; Epilog
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
    RET
InitConsole ENDP

; Hex to UTF16LE
HexToUTF16LE PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h

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

    ; Epilog
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
    RET
HexToUTF16LE ENDP

InternalError PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h
    
    ; Get last error
    XOR RCX, RCX
    CALL GetLastError

    ; Convert to Unicode
    MOV RCX, RAX
    PUSH RAX
    CALL HexToUTF16LE

    ; Update error string
    LEA RCX, TextInternalError
    ADD RCX, TextInternalError_LEN * 2
    SUB RCX, 6 * 2 + 1
    MOV QWORD PTR [RCX], RAX

    ; Write error
    M_WRITECONSOLE TextInternalError, TextInternalError_LEN
    POP RAX
p_exit::
    ; Pause and exit
    CALL PauseAndExit

    ; Epilog (future proofing)
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
InternalError ENDP

; Pause And Exit Procedure
PauseAndExit PROC
    LOCAL ExitCode: QWORD

    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 30h    ; 20h for shadow space, 8h for local variable, 8h for 1 stack variable (ReadConsoleW)

    ; Move exit code into local variable
    MOV ExitCode, RCX

    ; Write the exit line, wait for enter
    M_WRITECONSOLE TextToExit, TextToExit_LEN
    M_READCONSOLE

    ; Exit
    MOV RCX, ExitCode
    CALL ExitProcess
PauseAndExit ENDP