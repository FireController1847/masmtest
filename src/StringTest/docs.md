# winutil.inc
## Constants
`STD_INPUT_HANDLE (-10)`  
`STD_OUTPUT_HANDLE (-11)`  
`MAX_PATH (260)`  

## Data
### Text
**TextToExit** `WORD`: Press enter to exit.  
**TextToExit_LEN** `CONST`: 23  

### Standard I/O
Handles are initialized via `InitConsole`.

**StdOutHandle** `QWORD`: ?  
**StdInHandle** `QWORD`: ?  
**StdInBuffer** `WORD`: `MAX_PATH` DUP (?)
**StdInCharsWritten** `DWORD`: ?

## Macros
### M_WRITECONSOLE
**Args:** `W_STR`, `W_STRLEN`  
**See:** [WriteConsole](https://learn.microsoft.com/en-us/windows/console/writeconsole)  
  
Loads the effective address of W_STR, then writes W_STRLEN characters of it to the
console output.

### M_READCONSOLE
**Args:** `N/A`  
**See:** [ReadConsole](https://learn.microsoft.com/en-us/windows/console/readconsole)  
  
Waits for console input and then an 'ENTER' press. Writes the result into `StdInBuffer`
and the number of characters written into `StdInCharsWritten`.

## Procedures
### Crash
**Args**: `N/A`  
**C Signature**:
```c
void Crash();
```
**See**: [GetLastError](https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror), [ExitProcess](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess)

Gets the last error for debugging, then exits the process with an
exit code of the last error.

### InitConsole
**Args**: `N/A`  
**C Signature**:
```c
void InitConsole();
```
**See**: [Console Handles](https://learn.microsoft.com/en-us/windows/console/console-handles), [GetStdHandle](https://learn.microsoft.com/en-us/windows/console/getstdhandle), [SetLastError](https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-setlasterror)  

Initializes a program to be a console program. Think of it as "Initialize Console
Program." Sets the last error to zero, then fetches the `StdInHandle` and `StdOutHandle`.

### PauseAndExit
**Args**: `RCX: ExitCode`  
**C Signature**:
```c
void PauseAndExit(
    [in] QWORD  ExitCode
);
```
**See**: [Data#Text](#text), [ExitProcess](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess)  

Writes the `TextToExit` string to the screen, waits for an 'ENTER' press from the user,
and then exits the process with the specified exit code.
