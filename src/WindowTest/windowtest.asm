INCLUDELIB kernel32.lib
INCLUDE winutil.inc

; Constants
WS_OVERLAPPED EQU 00000000h
WS_CAPTION EQU 00C00000h
WS_SYSMENU EQU 00080000h
WS_THICKFRAME EQU 00040000h
WS_MINIMIZEBOX EQU 00020000h
WS_MAXIMIZEBOX EQU 00010000h
WS_OVERLAPPEDWINDOW EQU WS_OVERLAPPED OR WS_CAPTION OR WS_SYSMENU OR WS_THICKFRAME OR WS_MINIMIZEBOX OR WS_MAXIMIZEBOX

; Prototypes
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
ALIGN 16

; Structures
S_WNDCLASSEXW STRUCT
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
S_WNDCLASSEXW ENDS

MSG     STRUCT
    hwnd        QWORD   ?
    message     DWORD   ?
    wParam      QWORD   ?
    lParam      QWORD   ?
    time        DWORD   ?
    pt          QWORD   ?
    lPrivate    DWORD   ?
MSG     ENDS

; Strings
StrWindowClassName_LEN  EQU     22  ; MASMTEST Window Class
StrWindowClassName      WORD    4Dh, 41h, 53h, 4Dh, 54h, 45h, 53h, 54h, 20h, 57h, 69h, 6Eh, 64h, 6Fh, 77h, 20h
                        WORD    43h, 6Ch, 61h, 73h, 73h, 00h
StrWindowName_LEN       EQU     17  ; MASM Test Window
StrWindowName           WORD    4Dh, 41h, 53h, 4Dh, 20h, 54h, 65h, 73h, 74h, 20h, 57h, 69h, 6Eh, 64h, 6Fh, 77h
                        WORD    00h

; Variables
MemWinClassAttr     S_WNDCLASSEXW   <>
MemModuleHandle     QWORD           ?
MemHwnd             QWORD           ?
MemMessage          MSG             <>

.CODE
WindowProc PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h

    ; Handle Quit Message
    CMP RDX, 10h
    JNE def
    MOV RCX, 0
    CALL PostQuitMessage
    CALL ExitProcess
    JMP no_def

def::
    ; Default Message Processor
    CALL DefWindowProcW

    ; Epilog
no_def::
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
    RET
WindowProc ENDP

main PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 60h    ; 20h for shadow space, 40h for 8 stack variables

    ; Get & Assign Module Handle
    XOR RCX, RCX
    CALL GetModuleHandleW
    CMP RAX, 0
    JZ Crash
    MOV MemModuleHandle, RAX

    ; Populate WNDCLASS Values
    MOV MemWinClassAttr.hInstance, RAX
    LEA RCX, WindowProc
    MOV MemWinClassAttr.lpfnWndProc, RCX
    LEA RCX, StrWindowClassName
    MOV MemWinClassAttr.lpszClassName, RCX
    MOV MemWinClassAttr.cbSize, SIZEOF MemWinClassAttr

    ; Register WNDCLASS
    LEA RCX, MemWinClassAttr
    CALL RegisterClassExW
    CMP RAX, 0
    JZ Crash

    ; Create Window
    MOV RCX, 0
    LEA RDX, StrWindowClassName
    LEA R8, StrWindowName
    MOV QWORD PTR [RSP + 20h], 80000000h    ; X
    MOV QWORD PTR [RSP + 28h], 80000000h    ; Y
    MOV QWORD PTR [RSP + 30h], 80000000h    ; nWidth
    MOV QWORD PTR [RSP + 38h], 80000000h    ; nHeight
    MOV QWORD PTR [RSP + 40h], 0            ; hWndParent
    MOV QWORD PTR [RSP + 48h], 0            ; hMenu
    MOV R9, MemModuleHandle
    MOV QWORD PTR [RSP + 50h], R9           ; hInstance
    MOV QWORD PTR [RSP + 58h], 0            ; lpParam
    XOR R9, R9
    MOV R9, WS_OVERLAPPEDWINDOW
    CALL CreateWindowExW
    MOV MemHwnd, RAX
    CMP RAX, 0
    JZ Crash

    ; Show Window
    MOV RCX, RAX
    MOV RDX, 1
    CALL ShowWindow

    ; Call Message Loop
message_loop:
    ; Get Message
    LEA RCX, MemMessage
    MOV RDX, 0
    MOV R8, 0
    MOV R9, 0
    CALL GetMessageW
    CMP RAX, 0
    JZ exit_process

    ; Translate & Dispatch
    LEA RCX, MemMessage
    CALL TranslateMessage
    LEA RCX, MemMessage
    CALL DispatchMessageW
    JMP message_loop

    ; Epilog
exit_process::
    CALL ExitProcess
    ADD RSP, 60h
    MOV RSP, RBP
    POP RBP
main ENDP
END