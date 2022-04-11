       .386P
        .model  flat
        extern  _printf:near
        public  _main

        .code
_main:
        push    esi                     ; callee-save registers
        push    edi
        
        mov     esi, 1                  ; current value
        mov     edi, 31                 ; counter                
L1:
        push    esi                     ; push value to print
        push    offset format           ; push address of format string
        call    _printf
        add     esp, 8                  ; pop off parameters passed to printf
        add     esi, esi                ; double value
        dec     edi                     ; keep counting
        jnz     L1

        pop     edi
        pop     esi
        ret
        
format: byte    '%d', 10, 0

        end
