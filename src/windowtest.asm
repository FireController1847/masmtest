INCLUDELIB kernel32.lib
INCLUDELIB user32.lib

; Constants
STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11
WS_OVERLAPPED EQU 00000000h
WS_CAPTION EQU 00C00000h
WS_SYSMENU EQU 00080000h
WS_THICKFRAME EQU 00040000h
WS_MINIMIZEBOX EQU 00020000h
WS_MAXIMIZEBOX EQU 00010000h
WS_OVERLAPPEDWINDOW EQU WS_OVERLAPPED OR WS_CAPTION OR WS_SYSMENU OR WS_THICKFRAME OR WS_MINIMIZEBOX OR WS_MAXIMIZEBOX

; Prototypes
ExitProcess PROTO
GetStdHandle PROTO
WriteConsoleW PROTO
SetLastError PROTO
GetLastError PROTO
GetModuleHandleW PROTO
RegisterClassExW PROTO
CreateWindowExW PROTO
ShowWindow PROTO
GetMessageW PROTO
TranslateMessage PROTO
DispatchMessageW PROTO
DefWindowProcW PROTO
PostQuitMessage PROTO

.DATA
; Structures
WNDCLASSEXW    STRUCT
    cbSize          DWORD   0
    style           DWORD   0
    lpfnWndProc     QWORD   0
    cbClsExtra      DWORD   0
    cbWndExtra      DWORD   0
    hInstance       QWORD   0
    hIcon           QWORD   0
    hCursor         QWORD   0
    hbrBackground   QWORD   0
    lpszMenuName    QWORD   0
    lpszClassName   QWORD   0
    hIconSm         QWORD   0
WNDCLASSEXW   ENDS

MSG         STRUCT
    hwnd            QWORD   ?
    message         DWORD   ?
    wparam          QWORD   ?
    lparam          QWORD   ?
    times           DWORD   ?
    pt              QWORD   ?
    lPrivate        DWORD   ?
MSG         ENDS

; Strings
StrWindowClassName      WORD    4Dh, 41h, 53h, 4Dh, 54h, 45h, 53h, 54h, 20h, 57h, 69h, 6Eh, 64h, 6Fh, 77h, 20h, 43h, 6Ch, 61h, 73h, 73h, 00h    ; MASMTEST Window Class
StrWindowName           WORD    4Dh, 41h, 53h, 4Dh, 20h, 54h, 65h, 73h, 74h, 20h, 57h, 69h, 6Eh, 64h, 6Fh, 77h, 00h ; MASM Test Window
StrDebugMessageLoop     WORD    4Dh, 45h, 53h, 53h, 41h, 47h, 45h, 20h, 4Ch, 4Fh, 4Fh, 50h, 0Dh, 0Ah, 00h           ; MESSAGE LOOP
StrDebugWindowProc      WORD    57h, 49h, 4Eh, 44h, 4Fh, 57h, 50h, 52h, 4Fh, 43h, 0Dh, 0Ah, 00h     ; WINDOWPROC

; Standard I/O
StdOutHandle    QWORD   ?
StdInHandle     QWORD   ?
StdInBuffer     WORD    8 DUP (?)
StdInCharsWritten   BYTE    ?
StdPathBuffer   WORD    260 DUP (?)

; Variables
LastMessage     MSG     <>
Hwnd            QWORD   ?

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

; Clear Last Message
ClearLastMessage PROC
    MOV LastMessage.hwnd, 0
    MOV LastMessage.message, 0
    MOV LastMessage.wparam, 0
    MOV LastMessage.lparam, 0
    MOV LastMessage.times, 0
    MOV LastMessage.pt, 0
    MOV LastMessage.lPrivate, 0
ClearLastMessage ENDP

WindowProc PROC FRAME
    ;PUSH RCX
    ;PUSH RDX
    ;PUSH R8
    ;PUSH R9
    ;MOV RCX, StdOutHandle
    ;LEA RDX, StrDebugWindowProc
    ;MOV R8, LENGTHOF StrDebugWindowProc
    ;CALL WriteConsoleW
    ;POP R9
    ;POP R8
    ;POP RDX
    ;POP RCX

    CMP RDX, 10h
    JNE def
    MOV RCX, 0
    CALL PostQuitMessage
    MOV RAX, ExitProcess
    JMP ExitProcess

def:
    MOV RAX, DefWindowProcW
    JMP RAX
.ENDPROLOG
WindowProc ENDP

; Microsoft Window Procedure
main PROC
    LOCAL wc: WNDCLASSEXW

    ; Clear Registers
    CALL ClearRegisters
    CALL SetLastError
    MOV RCX, 0

    ; Fetch console handles
    MOV RCX, STD_OUTPUT_HANDLE
    CALL GetStdHandle
    MOV StdOutHandle, RAX
    MOV RCX, STD_INPUT_HANDLE
    CALL GetStdHandle
    MOV StdInHandle, RAX

    ; Get & Assign Module Handle
    CALL GetModuleHandleW
    MOV wc.hInstance, RAX

    ; Assign WNDCLASS Values
    LEA RAX, WindowProc
    MOV wc.lpfnWndProc, RAX
    LEA RAX, StrWindowClassName
    MOV wc.lpszClassName, RAX
    MOV wc.cbSize, SIZEOF wc

    ; Register WNDCLASS
    LEA RCX, wc
    CALL RegisterClassExW

    ; Create Window
    MOV RCX, 0
    LEA RDX, [StrWindowClassName]
    LEA R8, [StrWindowName]
    XOR R9, R9
    MOV R9D, WS_OVERLAPPEDWINDOW
    SUB RSP, 40h
    PUSH 0              ; lpParam
    PUSH wc.hInstance   ; hInstance
    PUSH 0              ; hMenu
    PUSH 0              ; hWndParent
    PUSH 0              ; nHeight
    PUSH 0              ; nWidth
    PUSH 0              ; Y
    PUSH 0              ; X
    CALL CreateWindowExW
    POP RCX
    POP RCX
    POP RCX
    POP RCX
    POP RCX
    POP RCX
    POP RCX
    POP RCX
    ADD RSP, 40h
    MOV Hwnd, RAX
    TEST RAX, RAX
    JZ exit_process

    ; Show Window
    CALL ClearRegisters
    MOV RCX, Hwnd
    XOR RDX, RDX
    MOV DX, 1
    CALL ShowWindow

    ; Call Message Loop
message_loop:
    CALL ClearRegisters
    CALL ClearLastMessage
    ; MOV RCX, StdOutHandle
    ; LEA RDX, StrDebugMessageLoop
    ; MOV R8, LENGTHOF StrDebugMessageLoop
    ; CALL WriteConsoleW
    LEA RCX, LastMessage
    MOV RDX, 0
    MOV R8, 0
    MOV R9, 0
    CALL GetMessageW
    TEST RAX, 0
    JNZ exit_process
    LEA RCX, LastMessage
    CALL TranslateMessage
    LEA RCX, LastMessage
    CALL DispatchMessageW
    JMP message_loop
exit_process:
    CALL ExitProcess
    RET
main ENDP
END