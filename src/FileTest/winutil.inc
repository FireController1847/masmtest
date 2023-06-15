INCLUDELIB kernel32.lib

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
TextToExit      WORD    0Dh, 0Ah, 50h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh, 20h, 65h, 78h, 69h, 74h, 2Eh, 00h   ; Press enter to exit.

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

; Initializes Console
InitConsole PROC
    ; Clear registers
    XOR RCX, RCX
    CALL SetLastError
    CALL ClearRegisters

    ; Fetch console handles
    XOR RCX, RCX
    MOV ECX, STD_OUTPUT_HANDLE
    CALL GetStdHandle
    JZ Crash
    MOV StdOutHandle, RAX
    XOR RCX, RCX
    MOV ECX, STD_INPUT_HANDLE
    CALL GetStdHandle
    JZ Crash
    MOV StdInHandle, RAX
InitConsole ENDP

PauseAndExit PROC
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
PauseAndExit ENDP