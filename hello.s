         .global go

         .data
msg:     .ascii  "Hello, World\n"
handle:  .int    0
written: .int    0

         .text
go:
         /* handle = GetStdHandle(-11) */
         pushl   $-11
         call    _GetStdHandle@4
         mov     %eax, handle

         /* WriteConsole(handle, &msg[0], 13, &written, 0) */
         pushl   $0
         pushl   $written
         pushl   $13
         pushl   $msg
         pushl   handle
         call    _WriteConsoleA@20

         /* ExitProcess(0) */
         pushl   $0
         call    _ExitProcess@4
