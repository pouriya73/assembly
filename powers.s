       .global _main

        .text
format: .asciz  "%d\n"

_main:
        pushl   %esi                    /* callee save registers */
        pushl   %edi
        
        movl    $1, %esi                /* current value */
        movl    $31, %edi               /* counter */
L1:
        pushl   %esi                    /* push value of number to print */
        pushl   $format                 /* push address of format */
        call    _printf
        addl    $8, %esp

        addl    %esi, %esi              /* double value */
        decl    %edi                    /* keep counting */
        jnz     L1
        
        popl    %edi
        popl    %esi
        ret
