# assembly
OpenGL Programming in NASM for Win32

For fun, here is a complete assembly language program that implements an OpenGL application running under GLUT on Windows systems


Differences between NASM, MASM, and GAS
The complete syntactic specification of each assembly language can be found elsewhere, but you can learn 99% of what you need to know by looking at a comparison table:

Good to know:

NASM and MASM use what is sometimes called the Intel syntax, while GAS uses what is called the AT&T syntax.

GAS uses % to prefix registers

GAS is source(s) first, destination last; MASM and NASM go the other way.

GAS denotes operand sizes on instructions (with b, w, l suffixes), rather than on operands
GAS uses $ for immediates, but also for addresses of variables.

GAS puts rep/repe/repne/repz/repnz prefixes on separate lines from the instructions they modify

MASM tries to simplify things for the programmer but makes headaches instead:

it tries to "remember" segments, variable sizes and so on.

The result is a requirement for stupid ASSUME directives, and the inability to tell what an instruction does by looking at it (you have to go look for declarations; e.g. dw vs. equ).


MASM writes FPU registers as ST(0), ST(1), etc.


NASM treats labels case-sensitively; MASM is case-insensitive.




There are many object file formats. Some you should know about include


OMF: used in DOS but has 32-bit extensions for Windows. Old.

AOUT: used in early Linux and BSD variants

COFF: "Common object file format"

Win, Win32: Microsoft’s version of COFF, not exactly the same! Replaces OMF.

Win64: Microsoft’s format for Win64.

ELF, ELF32: Used in modern 32-bit Linux and elsewhere

ELF64: Used in 64-bit Linux and elsewhere

macho32: NeXTstep/OpenStep/Rhapsody/Darwin/macOS 32-bit

macho64: NeXTstep/OpenStep/Rhapsody/Darwin/macOS 64-bit

The NASM documentation has great descriptions of these.

You’ll need to get a linker that (1) understands the object file formats you produce, and (2) can write executables for the operating systems you want to run code on.

Some linkers out there include

LINK.EXE, for Microsoft operating systems.


which exists on all Unix systems; Windows programmers get this in any gcc distribution.


