        .386P
        .model  flat
        extern  _ExitProcess@4:near
        extern  _GetStdHandle@4:near
        extern  _WriteConsoleA@20:near
        public  _go

        .data
msg     byte    'Hello, World', 10
handle  dword   ?
written dword   ?

        .stack

        .code
_go:    
        ; handle = GetStdHandle(-11)
        push    -11
        call    _GetStdHandle@4
        mov     handle, eax

        ; WriteConsole(handle, &msg[0], 13, &written, 0)
        push    0
        push    offset written
        push    13
        push    offset msg
        push    handle
        call    _WriteConsoleA@20

        ; ExitProcess(0)
        push    0
        call    _ExitProcess@4

        end
