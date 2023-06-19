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

; Strings
TextNewline_LEN     EQU     3   ; CRLF
TextNewline         WORD    0Dh, 0Ah, 00h
TextToExit_LEN      EQU     23  ; Press enter to exit.
TextToExit          WORD    0Dh, 0Ah, 50h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh
                    WORD    20h, 65h, 78h, 69h, 74h, 2Eh, 00h

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