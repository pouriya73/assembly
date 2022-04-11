        .model  small

        .stack  128

        .code
start:  mov     ax, @data
        mov     ds, ax
        mov     ah, 9
        lea     dx, Msg
        int     21h
        mov     ah, 4ch
        int     21h

        .data
Msg     byte    'Hello, there.', 13, 10, '$'

        end     start
