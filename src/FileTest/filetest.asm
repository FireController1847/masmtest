INCLUDELIB kernel32.lib
INCLUDE winstruct.inc
INCLUDE winutil.inc

; Prototypes
GetFileAttributesW PROTO
CreateFileW PROTO
GetFileSizeEx PROTO
HeapCreate PROTO
HeapAlloc PROTO
HeapFree PROTO
HeapDestroy PROTO
ReadFile PROTO
CloseHandle PROTO
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
fileSize        QWORD   ?
hFileHeap       QWORD   ?
ptrFileMem      QWORD   ?
fileBytesRead   WORD    ?

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
    SHL RAX, 8

    ; Epilog
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
    RET
HexToUnicode ENDP

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
    ; Pause and exit
    CALL PauseAndExit

    ; Epilog (future proofing)
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
InternalError ENDP


main PROC
    LOCAL CharsWritten: QWORD

    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 40h    ; 20h shadow space, 8h for local QWORD CharsWritten, 18h for 3 stack arguments

    ; Initialize console
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
    CALL GetFileAttributesW
    CMP EAX, -1 ; INVALID_FILE_ATTRIBUTES (0xFFFFFFFF)
    ; TODO: Instead of just erroring, re-prompt the user for a valid file.
    JNE p_skip_invalid_file_path
    CALL InternalError
p_skip_invalid_file_path::
    MOV fileAttributes, RAX
    CALL ClearRegisters

    ; Print input to screen
    M_WRITECONSOLE TextTestfilePath, CharsWritten
    M_WRITECONSOLE TextNewline, LENGTHOF TextNewline
    M_WRITECONSOLE TextNewline, LENGTHOF TextNewline

    ; Open the file for GENERIC_READ
    CALL ClearRegisters
    LEA RCX, TextTestfilePath
    MOV RDX, 80000000h      ; GENERIC_READ
    MOV R8, 00000001h       ; FILE_SHARE_READ
    MOV R9, 0h              ; NULL
    MOV QWORD PTR [RSP + 20h], 3
    MOV QWORD PTR [RSP + 28h], 80h
    MOV QWORD PTR [RSP + 30h], 00h
    CALL CreateFileW
    CMP EAX, -1
    JNE p_skip_invalid_create_file
    CALL InternalError
p_skip_invalid_create_file::
    MOV hFile, RAX

    ; Get the file size
    MOV RCX, hFile
    LEA RDX, fileSize
    CALL GetFileSizeEx
    JNZ p_skip_invalid_filesize
    CALL InternalError
p_skip_invalid_filesize::

    ; Create a new heap for the file
    MOV RCX, 0
    MOV RDX, 0
    MOV R8, RAX
    CALL HeapCreate
    JNZ p_skip_fail_heapcreate
    CALL InternalError
p_skip_fail_heapcreate::
    MOV hFileHeap, RAX

    ; Allocate the file memory
    MOV RCX, RAX
    MOV RDX, 00000008h
    MOV R8, fileSize
    CALL HeapAlloc
    JNZ p_skip_fail_heapalloc
    CALL InternalError
p_skip_fail_heapalloc::
    MOV ptrFileMem, RAX

    ; Read the file into memory
    MOV RCX, hFile
    MOV RDX, ptrFileMem
    MOV R8, fileSize
    LEA R9, fileBytesRead
    MOV QWORD PTR [RSP + 20h], 00h
    CALL ReadFile
    JNZ p_skip_fail_readfile
    CALL InternalError
p_skip_fail_readfile:
    ; Close the file
    MOV RCX, hFile
    CALL CloseHandle

    ; The file is now in memory.

    ; Print the file
    MOV RCX, StdOutHandle
    MOV RDX, ptrFileMem
    ADD RDX, 2h
    MOV R8, fileSize
    SHR R8, 1
    SUB R8, 1
    CALL WriteConsoleW
    CMP RAX, 0
    JZ Crash

    ; Free allocated file memory
    MOV RCX, hFileHeap
    MOV RDX, 0h
    MOV R8, ptrFileMem
    CALL HeapFree
    JNZ p_skip_fail_heapfree
    CALL InternalError
p_skip_fail_heapfree::

    ; Destroy heap
    MOV RCX, hFileHeap
    CALL HeapDestroy
    JNZ p_skip_fail_heapdestroy
    CALL InternalError
p_skip_fail_heapdestroy::

    ; Print a newline
    M_WRITECONSOLE TextNewline, LENGTHOF TextNewline

    ; Pause and exit
    CALL PauseAndExit

    ; Epilog (future proofing)
    ADD RSP, 40h
    MOV RSP, RBP
    POP RBP
main ENDP
END
