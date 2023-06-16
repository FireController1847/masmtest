INCLUDELIB kernel32.lib
INCLUDE winstruct.inc
INCLUDE winutil.inc

; Prototypes
FindFirstFileW PROTO
GetFileAttributesW PROTO
CreateFileW PROTO
GetLastError PROTO

.DATA
ALIGN 16

; Strings
TextInvalidName     WORD    54h, 68h, 65h, 20h, 66h, 69h, 6Ch, 65h, 6Eh, 61h, 6Dh, 65h, 2Ch, 20h, 64h, 69h
                    WORD    72h, 65h, 63h, 74h, 6Fh, 72h, 79h, 20h, 6Eh, 61h, 6Dh, 65h, 2Ch, 20h, 6Fh, 72h
                    WORD    20h, 76h, 6Fh, 6Ch, 75h, 6Dh, 65h, 20h, 6Ch, 61h, 62h, 65h, 6Ch, 20h, 73h, 79h
                    WORD    6Eh, 74h, 61h, 78h, 20h, 69h, 73h, 20h, 69h, 6Eh, 63h, 6Fh, 72h, 72h, 65h, 63h
                    WORD    74h, 2Eh, 0Dh, 0Ah, 00h
TextErrorCode0002   WORD    0Dh, 0Ah, 54h, 68h, 65h, 20h, 73h, 79h, 73h, 74h, 65h, 6Dh, 20h, 63h, 61h, 6Eh
                    WORD    6Eh, 6Fh, 74h, 20h, 66h, 69h, 6Eh, 64h, 20h, 74h, 68h, 65h, 20h, 66h, 69h, 6Ch
                    WORD    65h, 20h, 73h, 70h, 65h, 63h, 69h, 66h, 69h, 65h, 64h, 2Eh, 00h       ; The system cannot find the file specified.
TextInternalError   WORD    0Dh, 0Ah, 41h, 6Eh, 20h, 69h, 6Eh, 74h, 65h, 72h, 6Eh, 61h, 6Ch, 20h, 65h, 72h
                    WORD    72h, 6Fh, 72h, 20h, 68h, 61h, 73h, 20h, 6Fh, 63h, 63h, 75h, 72h, 72h, 65h, 64h
                    WORD    20h, 61h, 6Eh, 64h, 20h, 74h, 68h, 65h, 20h, 70h, 72h, 6Fh, 67h, 72h, 61h, 6Dh
                    WORD    20h, 77h, 69h, 6Ch, 6Ch, 20h, 6Eh, 6Fh, 77h, 20h, 63h, 6Ch, 6Fh, 73h, 65h, 2Eh
                    WORD    20h, 28h, 30h, 78h, 30h, 30h, 30h, 30h, 29h, 0Dh, 0Ah, 00h
TextPrompt          WORD    45h, 6Eh, 74h, 65h, 72h, 20h, 66h, 69h, 6Ch, 65h, 6Eh, 61h, 6Dh, 65h, 3Ah, 20h  ; Enter filename: 
TextTestfilePath    WORD    260 DUP (?)
UnicodeNumbers      WORD    30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h

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

; TODO: Rewrite this code to be an independent "print error" procedure.

; ===================== COMMENT ON P_PRINT_ERROR_LOOP =====================
;     This code directly takes a Windows error code (0xFFFF) and converts
; it to the Unicode equivilant to print "F" "F" "F" "F" (or whatever
; the error code may by).
; 
;     It does so by first loading the whole error code string, which
; contains the 0x0000 template. Then it begins the loop to iterate
; the error code's value (say ABCD) and convert it.
; 
;     It checks if it's the first character (because if it is, we
; don't need to shift over any). It matches that to the Unicode
; Number map. In the case of ABCD, it would "not shift" and then
; black out the leftmost three values, leaving you with 000D. 
; 
;     It then converts F to the Unicode value for F, and stores it in
; the error string which we loaded before the loop. Oh, and it does
; this backwards. So it updates the last value in 0x0000 to leave 0x000D.
; On the second, third, and fourth iteration, it does essentially
; the same thing, except this time we have an inner loop shifting
; (4-i) number of times (that is, when i=4, j=0; i=3, j=1; i=2, j=2;
; i=1, j=3). This gives us the ability to shift in reverse to how
; we print.
; 
;     And so, the second iteration leaves 000C (shifting from ABCD => 0ABC,
; then ANDing with 000F to leave 000C). The third, 000B (shifting from
; ABCD => 0ABC => 00AB, then ANDing with 000F to leave 000B). And the
; fourth, 000A. (shifting from ABCD => 0ABC => 00AB => 000A, then ANDing
; with 000F to leave 000A).
; 
;     Since we write the value in each loop backwards in the string,
; it writes 0x000D, 0x00CD, 0x0BCD, and 0xABCD on the first, second,
; third, and fourth iterations respectively.
; 
;     And then we print it!
; ===========================================================================
InvalidFilePath PROC
    ; Get the last error
    XOR RCX, RCX
    CALL GetLastError

    ; Print error
    MOV RCX, 4                  ; Iterate for 4 characters
    LEA R10, TextInternalError  ; Load internal error string into R10 (used later)
    ADD R10, 74 * 2             ; IErr string is 74 chars long * 2 for wide chars
    SUB R10, 6 * 2              ; Error code is 6 chars in * 2 for wide chars
p_print_error_loop::
    XOR RDX, RDX                    ; Clear RDX
    MOV DX, AX                      ; Move err code into DX
    CMP RCX, 4                      ; Check if counter is the first charatcer
    JE p_print_error_exit_loop_shr  ; If it is, don't shift
    MOV R9, 4                       ; If it's not, mov 4 into R9
    SUB R9, RCX                     ; Subtract R9 by the counter (so 4 - i)
p_print_error_loop_shr::
    SHR DX, 4                   ; Shift DX right 4 bytes
    DEC R9                      ; Decrement R9 counter (j)
    JNZ p_print_error_loop_shr  ; Loop to shift again
p_print_error_exit_loop_shr::
    AND DX, 1111b               ; Keep only the rightmost character
    LEA R9, UnicodeNumbers      ; Load UnicodeNumbers address space
    ADD R9, RDX                 ; Directly convert R9's value into the address for the Unicode of its hexidecimal equivilant
    ADD R9, RDX                 ; Do it again, cuz wide chars
    MOV DX, WORD PTR [R9]       ; Move the Unicode's literal value into DX
    DEC RCX                     ; Decrement outer loop
    MOV [R10 + RCX * 2], DX     ; Move the Unicode's literal value into the character string in R10 (the internal error string)
    JNZ p_print_error_loop      ; Loop if we haven't completed all four
    PUSH RAX
    SUB RSP, 20h
    M_WRITECONSOLE TextInternalError, 74
    ADD RSP, 20h
    POP RAX

    ; Print known errors
    CMP RAX, 02h
    JE p_file_not_found
    JMP p_exit

    ; File not found
p_file_not_found:
    M_WRITECONSOLE TextErrorCode0002, 45

    ; Pause and exit
p_exit::
    CALL PauseAndExit
InvalidFilePath ENDP

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
    CALL GetFileAttributesW
    CMP EAX, -1 ; INVALID_FILE_ATTRIBUTES (0xFFFFFFFF)
    ; TODO: Instead of just erroring, re-prompt the user for a valid file.
    JNE SkipInvalidFilePath
    LEA RCX, InvalidFilePath
    JMP RCX
SkipInvalidFilePath:
    CALL ClearRegisters
    M_WRITECONSOLE TextTestfilePath, CharsWritten

    ; Exit process
    CALL ClearRegisters
    CALL PauseAndExit
main ENDP
END
