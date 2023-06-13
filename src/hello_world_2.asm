INCLUDELIB kernel32.lib

; =========================
; =     HELLO WORLD 2     =
; =========================
; Title: Hello World 2
; Author: FireController#1847
; Description:
;       An improved version of Hello World
;       which contains error checking.


; Constants
STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11

; Prototypes
GetStdHandle PROTO
WriteConsoleW PROTO
ReadConsoleW PROTO
SetLastError PROTO
GetLastError PROTO
ExitProcess PROTO

.DATA
; Strings
UnicodeNumbers  WORD    30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h  ; 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d, e, f
TextNewline     WORD    0Dh, 0Ah, 00h   ; CRLF
TextToExit      WORD    0Dh, 0Ah, 50h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh, 20h, 65h, 78h, 69h, 74h, 2Eh, 00h   ; Press enter to exit.
TextHelloWorld  WORD    48h, 65h, 6Ch, 6Ch, 6Fh, 2Ch, 20h, 77h, 6Fh, 72h, 6Ch, 64h, 21h, 00h  ; Hello, world!

; Standard I/O
StdOutHandle        QWORD   ?
StdInHandle         QWORD   ?
StdInBuffer         WORD    8 DUP (?)
StdInCharsWritten   BYTE    ?

.CODE
; Clear Registers Procedure
ClearRegisters PROC
    XOR RAX, RAX
    XOR RCX, RCX
    XOR RDX, RDX
    XOR R8, R8
    XOR R9, R9
    RET
ClearRegisters ENDP

; Crash Procedure
Crash PROC
    CALL ClearRegisters
    CALL GetLastError
    LEA RCX, ExitProcess
    JMP RCX
Crash ENDP

; Main Procedure
main PROC
    ; Clear registers
    XOR RCX, RCX
    CALL SetLastError
    CALL ClearRegisters

    ; Fetch console handles
    MOV RCX, STD_OUTPUT_HANDLE
    CALL GetStdHandle
    JZ Crash
    MOV StdOutHandle, RAX
    MOV RCX, STD_INPUT_HANDLE
    CALL GetStdHandle
    JZ Crash
    MOV StdInHandle, RAX

    ; Print "Hello, world!"
    MOV RCX, StdOutHandle
    LEA RDX, TextHelloWorld
    MOV R8, LENGTHOF TextHelloWorld
    CALL WriteConsoleW
    JZ Crash

    ; Insert newline
    MOV RCX, StdOutHandle
    LEA RDX, TextNewline
    MOV R8, LENGTHOF TextNewline
    CALL WriteConsoleW
    JZ Crash

    ; Write exit line
    MOV RCX, StdOutHandle
    LEA RDX, TextToExit
    MOV R8, LENGTHOF TextToExit
    CALL WriteConsoleW
    JZ Crash

    ; Read text input
    MOV RCX, StdInHandle
    LEA RDX, StdInBuffer
    MOV R8, LENGTHOF StdInBuffer
    LEA R9, StdInCharsWritten
    CALL ReadConsoleW
    JZ Crash

    ; Exit
    XOR RCX, RCX
    LEA RCX, ExitProcess
    JMP RCX
main ENDP
END