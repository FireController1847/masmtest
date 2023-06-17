INCLUDELIB kernel32.lib

; Prototypes
HeapCreate PROTO
HeapAlloc PROTO
ExitProcess PROTO

.DATA
; Memory
hPrimaryHeap    QWORD   ?
ptrAllocated    QWORD   ?

.CODE
main PROC
    MOV RCX, 0
    MOV RDX, 0
    MOV R8, 0
    CALL HeapCreate
    MOV hPrimaryHeap, RAX
memory_leak:
    MOV RCX, hPrimaryHeap
    MOV RDX, 8h
    MOV R8, 0FFh
    CALL HeapAlloc
    JMP memory_leak


    CALL ExitProcess
main ENDP
END