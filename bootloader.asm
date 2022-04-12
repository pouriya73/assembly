Boot loader for a roll-your-own operating system

; loader.asm

PartEntry STRUC
        Bootable        db ?    ;80h = bootable, 00h = nonbootable
        BeginHead       db ?    ;beginning head
        BeginSector     db ?    ;beginning sector
        BeginCylinder   db ?    ;beginning cylinder
        FileSystem      db ?    ;name of file system
        EndHead         db ?    ;ending head
        EndSector       db ?    ;ending sector
        EndCylinder     db ?    ;ending cylinder
        StartSector     dd ?    ;starting sector (relative to beg. of disk)
        PartSectors     dd ?    ;number of sectors in partition
PartEntry ENDS

BootSector STRUC
        bsJump          db 0EBh, (extra - bsJump), 090h
          ; E9 XX XX or EB xx 90
        OemName       db 8 dup (?)    ; OEM name and version
        ; start of BIOS parameter block
        BytesPerSec   dw ?      ; bytes per sector
        SecPerClust   db ?      ; sectors per cluster
        ResSectors    dw ?      ; number of reserved sectors
        FATs          db ?      ; number of FATs
        RootDirEnts   dw ?      ; number of root directory entries
        Sectors       dw ?      ; total number of sectors (see HugeSectors)
        Media         db ?      ; media descriptor byte (0f0h for floppies)
        FATsecs       dw ?      ; number of sectors per FAT
        SecPerTrack   dw ?      ; sectors per track
        Heads         dw ?      ; number of heads
        HiddenSecs    dd ?      ; number of hidden sectors
        HugeSectors   dd ?      ; number of sectors if Sectors equals 0
        ; end of BIOS parameter block
        DriveNumber   db ?      ;
        Reserved1     db ?      ;
        BootSignature db ?      ;
        VolumeID      dd ?      ;
        VolumeLabel   db 11 dup (?)
        FileSysType   db 8 dup (?)
        extra           dw ?
BootSector ENDS

DirEntry STRUC
        FileName        db '????????'   ;name
        Extension       db '???'        ;extension
        Attributes      db ?            ;attributes
        Reserved        db 10 dup (?)   ;reserved
        Time            dw ?            ;time stamp
        Date            dw ?            ;date stamp
        StartCluster    dw ?            ;starting cluster
        FileSize        dd ?            ;file size
DirEntry ENDS

CR      EQU     0DH
LF      EQU     0AH

yonder segment para public use16 at 2000h
  org 0h
  destination proc far
  destination endp
yonder ends


code segment para public use16 '_CODE'
        .386
        assume cs:code, ds:code, es:code, ss:code
        org 7c00h
main PROC
MBR:
Boot bootsector < ,'BEROSET ',512,1,1,2,224,2880,0f0h,9,18,2,\
          0,0,0,0,29h,02a04063ch,'BEROSET 001',\
          'FAT12   ',07df1h>
over:
        mov     ax,cs               ;
        cli
        mov     ss,ax                   ; point ss:sp to CS:7c00h
        mov     sp,7c00h                ; which sets up a stack in first 64K
        sti
        mov     ds,ax
        mov     es,ax
;****************************************************************************
;
; CalcClustOff - calculates the starting logical sector number of
;               cluster 0, which isn't really a cluster, but the
;               number returned is useful for calculations converting
;               cluster number to logical sector
;
; INPUT:     ResSectors, FATsecs, FATs
; OUTPUT:    dx:ax contains the starting logical sector number
; DESTROYED: none
;
;****************************************************************************
CalcClustOff PROC
        xor     dh,dh
        mov     ax,[Boot.FatSecs]
        mov     dl,[Boot.FATs]
        mul     dx
        add     ax,[Boot.ResSectors]
        adc     dx,0
        ; now dx:ax = FATs * FATsecs + ResSectors
        mov     word ptr [ClustOffs],ax
        mov     word ptr [ClustOffs+2],dx
        mov     dx,20h                  ; bytes per dir entry
        mov     ax,[Boot.RootDirEnts]
        mul     dx                      ; multiply 'em out
        div     word ptr [Boot.BytesPerSec]  ; and divide by bytes/sec
        add     word ptr [ClustOffs],ax
        adc     word ptr [ClustOffs+2],dx ; create the aggregate
        mov     al,[Boot.SecPerClust] ;
        xor     ah,ah                   ;
        shl     ax,1                    ; AX = SecPerClust * 2
        sub     word ptr [ClustOffs],ax  ;
        sbb     word ptr [ClustOffs+2],0 ; propagate carry flag
;        mov     ax,word ptr [ClustOffs]   ;
;        mov     dx,word ptr [ClustOffs+2] ;
;        ret
CalcClustOff ENDP

;        mov     WORD ptr [ClustOffs],ax
;        mov     WORD ptr [ClustOffs+2],dx
        mov     bx,offset Boot
        call    CalcClust2 C,                                 \
                WORD ptr [(BootSector PTR bx).ResSectors],    \
                WORD ptr [(BootSector PTR bx).FATsecs],       \
                WORD ptr [(BootSector PTR bx).FATs]
        ; now dx:ax contains the logical sector for cluster 2
        call    LsectToGeom C,                                \
                WORD ptr [(BootSector PTR bx).HiddenSecs]  ,  \
                WORD ptr [((BootSector PTR bx).HiddenSecs)+2],\
                [(BootSector PTR bx).Heads],                  \
                [(BootSector PTR bx).SecPerTrack]

        mov     dl,[(BootSector PTR bx).DriveNumber]
        mov     bx,offset buff
retry1:
        mov     al,[(BootSector PTR MBR).SecPerClust]
        mov     ah,2h                   ; get ready to read
        int     13h
        jc      retry1
        ; now find our desired filename within buffer (which has the root dir)

        call    FindFile C, \
                bx, 200h * 40h, offset BootFileName
        xor     dh,dh
        mov     dl,[(BootSector PTR MBR).SecPerClust]
        mov     si,ax
        mov     ax,[(DirEntry PTR si).StartCluster]
        mul     dx
        add     ax,WORD ptr [ClustOffs]
        adc     dx,WORD ptr [ClustOffs+2]
        ; now dx:ax contains logical sector number for start of file

        call    LsectToGeom C, \
                WORD ptr [(BootSector PTR MBR).HiddenSecs]  ,  \
                WORD ptr [((BootSector PTR MBR).HiddenSecs)+2],\
                [(BootSector PTR MBR).Heads],                  \
                [(BootSector PTR MBR).SecPerTrack]
retry2:
        mov     si,offset Boot
        mov     dl,[(BootSector PTR si).DriveNumber]
        mov     ah,2h
        ; read in a cluster's worth of data
        mov     al,[(BootSector PTR si).SecPerClust]
        ; point to our magic location
        mov     bx,seg destination
        mov     es,bx
        mov     bx,offset destination
        int     13h
        jc      retry2
@@exit:
        jmp     destination
ENDP    main

;****************************************************************************
;
; LsectToGeom - converts from logical sector number to the physical
;               geometry (head, cylinder, track) in the form required
;               by the BIOS (Int 13h) disk read and write calls.
;
; INPUT:     dx:ax=lsect, HiddenSecs, Heads, SecPerTrack
; OUTPUT:    cx, dx are set with cylinder/track, and head respectively
; DESTROYED: none
;****************************************************************************
LsectToGeom PROC    C lHiddenSecs:DWORD,    \
                      lHeads:WORD, lSecPerTrack:WORD, buffer:DWORD
        USES    ax                      ;save registers we'll use
        stc                             ;add one additional
        adc     ax, WORD ptr [lHiddenSecs]   ;add starting sector
        adc     dx, WORD ptr [lHiddenSecs+2] ;
        div     [lSecPerTrack]          ;
        mov     cl,dl                   ;store sector in cl
        xor     dx,dx                   ;
        div     [lHeads]                ;
        mov     dh,dl                   ;store head in dh
        mov     ch,al                   ;store low 8 bits of cylinder in ch
        shr     ax,1                    ;
        shr     ax,1                    ;
        and     al,0c0h                 ;pass through two hi bits only
        or      cl,ah                   ;mov bits into location
        ret                             ;
LsectToGeom ENDP

;****************************************************************************
;
; CalcClust2  - calculates the starting logical sector number of
;               cluster 2, (the beginning of data space for
;               partitions).
;
; INPUT:     ResSectors, FATsecs, FATs
; OUTPUT:    dx:ax contains the starting logical sector number
; DESTROYED: none
;
;****************************************************************************
CalcClust2 PROC    C cResSectors:WORD, cFATsecs:WORD, cFATs:BYTE
        xor     dx,dx                   ;
        mov     ax,[cFATsecs]           ;
        mul     [cFATs]                 ;
        add     ax,[cResSectors]        ;
        adc     dx,0                    ;
        ret
CalcClust2 ENDP

;****************************************************************************
;
; FindFile -    given a memory buffer containing the directory data
;               and a static file name for which to search, this routine
;               finds the file and returns a pointer to its directory
;               entry in ds:si
;
; INPUT:        dirbuffer, filespec
; OUTPUT:       ax    contains pointer to directory entry (or NULL)
; DESTROYED:    none
;****************************************************************************

FindFile PROC C dirbuffer:WORD, limit:WORD, filespec:WORD
        USES    cx, dx, di, si, es
        mov     cx,ds                   ;
        mov     es,cx                   ; es and ds point to same segment
        cld                             ; always count forward
        mov     ax,[dirbuffer]          ; load 'em up
        add     [limit],ax
        mov     dx,[filespec]           ;
keepsearching:
        mov     cx,11                   ; size of dos filename (8.3)
        mov     si,dx                   ;
        mov     di,ax                   ;
        repe    cmpsb                   ; compare 'em
        jz      foundit                 ;
        add     ax,20h                  ; size of directory entry
        cmp     ax,[limit]
        jb      keepsearching
        xor     ax,ax

foundit:
        ret
FindFile ENDP


BootFileName  db  "BEROSET SYS"         ;the boot loader for this OS
; MBR           db  0200h DUP (?)
buff          db  0200h * 40h DUP (?)
ClustOffs     dd  ?
        org 7dfeh
        dw      0AA55h          ; signature byte
code ends

        END
