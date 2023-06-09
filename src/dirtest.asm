INCLUDELIB kernel32.lib

; Constants
STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11
MAX_PATH EQU 260

; Prototypes
GetStdHandle PROTO
WriteConsoleW PROTO
ReadConsoleW PROTO
ExitProcess PROTO
GetLastError PROTO
GetCurrentDirectoryW PROTO

.DATA
; Strings
TextNewline     WORD    0Dh, 0Ah, 00h   ; CRLF
TextToExit      WORD    0Dh, 0Ah, 50h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh, 20h, 65h, 78h, 69h, 74h, 2Eh, 00h   ; Press enter to exit.

; Standard I/O
StdOutHandle    QWORD   ?
StdInHandle     QWORD   ?
StdInBuffer     WORD    8 DUP (?)
StdInCharsWritten   BYTE    ?
StdPathBuffer   WORD    260 DUP (?)

.CODE
main PROC
    ; Clear registers
    XOR RAX, RAX
    XOR RCX, RCX
    XOR RDX, RDX
    XOR R8, R8
    XOR R9, R9

    ; Fetch console handles
    MOV RCX, STD_OUTPUT_HANDLE
    CALL GetStdHandle
    MOV StdOutHandle, RAX
    MOV RCX, STD_INPUT_HANDLE
    CALL GetStdHandle
    MOV StdInHandle, RAX

    ; Get the current directory
    MOV RCX, MAX_PATH
    LEA RDX, StdPathBuffer
    CALL GetCurrentDirectoryW

    ; Print current directory to console
    MOV RCX, StdOutHandle
    LEA RDX, StdPathBuffer
    MOV R8, LENGTHOF StdPathBuffer
    CALL WriteConsoleW

; Prompts the user to exit the process
PromptToExit:
    ; Insert newline
    MOV RCX, StdOutHandle
    LEA RDX, TextNewline
    MOV R8, LENGTHOF TextNewline
    CALL WriteConsoleW

    ; Write exit line
    MOV RCX, StdOutHandle
    LEA RDX, TextToExit
    MOV R8, LENGTHOF TextToExit
    CALL WriteConsoleW

    ; Read text input
    MOV RCX, StdInHandle
    LEA RDX, StdInBuffer
    MOV R8, LENGTHOF StdInBuffer
    LEA R9, StdInCharsWritten
    CALL ReadConsoleW

    ; Exit
    MOV RCX, 00h
    CALL ExitProcess
main ENDP
END