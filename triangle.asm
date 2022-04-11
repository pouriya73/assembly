        global  _main
        extern  _glClear@4
        extern  _glBegin@4
        extern  _glEnd@0
        extern  _glColor3f@12
        extern  _glVertex3f@12
        extern  _glFlush@0
        extern  _glutInit@8
        extern  _glutInitDisplayMode@4
        extern  _glutInitWindowPosition@8
        extern  _glutInitWindowSize@8
        extern  _glutCreateWindow@4
        extern  _glutDisplayFunc@4
        extern  _glutMainLoop@0

        section .text
title:  db      'A Simple Triangle', 0
zero:   dd      0.0
one:    dd      1.0
half:   dd      0.5
neghalf:dd      -0.5

display:
        push    dword 16384
        call    _glClear@4              ; glClear(GL_COLOR_BUFFER_BIT)
        push    dword 9
        call    _glBegin@4              ; glBegin(GL_POLYGON)
        push    dword 0
        push    dword 0
        push    dword [one]
        call    _glColor3f@12           ; glColor3f(1, 0, 0)
        push    dword 0
        push    dword [neghalf]
        push    dword [neghalf]
        call    _glVertex3f@12          ; glVertex(-.5, -.5, 0)
        push    dword 0
        push    dword [one]
        push    dword 0
        call    _glColor3f@12           ; glColor3f(0, 1, 0)
        push    dword 0
        push    dword [neghalf]
        push    dword [half]
        call    _glVertex3f@12          ; glVertex(.5, -.5, 0)
        push    dword [one]
        push    dword 0
        push    dword 0
        call    _glColor3f@12           ; glColor3f(0, 0, 1)
        push    dword 0
        push    dword [half]
        push    dword 0
        call    _glVertex3f@12          ; glVertex(0, .5, 0)
        call    _glEnd@0                ; glEnd()
        call    _glFlush@0              ; glFlush()
        ret

_main:
        push    dword [esp+8]           ; push argv
        lea     eax, [esp+8]            ; get addr of argc (offset changed :-)
        push    eax
        call    _glutInit@8             ; glutInit(&argc, argv)
        push    dword 0
        call    _glutInitDisplayMode@4
        push    dword 80
        push    dword 80
        call    _glutInitWindowPosition@8
        push    dword 300
        push    dword 400
        call    _glutInitWindowSize@8
        push    title
        call    _glutCreateWindow@4
        push    display
        call    _glutDisplayFunc@4
        call    _glutMainLoop@0
        ret
