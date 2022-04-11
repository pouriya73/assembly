        .model  small
        .stack  64                      ; 64 byte stack
        .386
        .code
start:  movzx   cx,byte ptr ds:[80h]    ; size of parameter string
        mov     ah, 40h                 ; write
        mov     bx, 1                   ; ... to standard output
        mov     dx, 81h                 ; ... the parameter string
        int     21h                     ; ... by calling DOS
        mov     ah, 4ch
        int     21h
        end     start             
