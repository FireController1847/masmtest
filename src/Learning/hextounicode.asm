INCLUDELIB kernel32.lib

; Prototypes
ExitProcess PROTO

.DATA
ALIGN 16

UnicodeNumbers      WORD    30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h
                    WORD    38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h

.CODE

; Hex To Unicode Procedure
; Converts the given value to its Unicode literal equivalent.
; ARG1  BYTE   The value to convert to unicode.
HexToUnicode PROC
    XOR RAX, RAX
    MOV RDX, 4
p_htu_loop::
    MOV R8, RCX
    CMP RDX, 4
    JE p_htu_shr_loop_exit
    MOV R9, 4
    SUB R9, RDX
p_htu_shr_loop::
    SHR R8, 4
    DEC R9
    JNZ p_htu_shr_loop
p_htu_shr_loop_exit::
    AND R8, 1111b
    LEA R9, UnicodeNumbers
    ADD R9, R8
    ADD R9, R8
    MOV AX, WORD PTR [R9]
    DEC RDX
    ROR RAX, 16
    JNZ p_htu_loop
    RET
HexToUnicode ENDP

main PROC
    MOV RCX, 0002h      ; Test value
    CALL HexToUnicode   ; After the call, RAX should contain the 4 bytes converted to their Unicode values

    CALL ExitProcess
main ENDP
END