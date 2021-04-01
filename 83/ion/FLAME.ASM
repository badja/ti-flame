;************************************************************
;
; Flame v1.0
; ==========
; for Ion on the TI-83/TI-83+
;
; by Badja
; 21 June 2001
;
; http://badja.calc.org
; badja@calc.org
;
; You may use this source code in your own programs, as long
; as you give me credit.
;
;************************************************************

      .nolist
      #include "ion.inc"
      .list
#ifdef TI83P
      .org  progstart-2
      .db   $BB,$6D
#else
      .org  progstart
#endif
      ret
      jr    nc,start
      .db   "Flame",0
start:

      ld    de,saferam1+1           ; fill array with zeros
      ld    hl,saferam1
      ld    (hl),0
      ld    bc,(16*47)-1
      ldir

      ld    ix,sprTorch             ; draw torch sprite
      ld    a,40
      ld    l,44
      ld    bc,(20*256)+2
      call  ionLargeSprite

animate:
      ld    hl,saferam1+(16*47)

      ld    c,16                    ; randomise bottom row of array
randomise:
      ld    b,0
      call  ionRandom
      ld    (hl),a
      inc   hl
      dec   c
      jr    nz,randomise

      ld    ix,saferam1+(16*46)+1

      ld    b,14                    ; generate flame column by column
generateFlame:
      push  bc

      ld    b,47                    ; calculate single column
generateColumn:
      ld    d,0                     ; calculate weighted average of three
      ld    h,d                     ; horizontal pixels below current pixel
      ld    l,(ix+16)
      add   hl,hl
      ld    e,(ix+15)
      add   hl,de
      ld    e,(ix+17)
      add   hl,de
      ld    a,l
      srl   h
      rra
      srl   h
      rra
      sub   2                       ; subtract from average so flame tapers off
      jr    nc,positive
      xor   a                       ; treat a negative result as zero
positive:
      ld    (ix),a                  ; store the result
      ld    de,-16                  ; move up to the row above
      add   ix,de
      djnz  generateColumn

      ld    de,(16*47)+1            ; move across to the next column
      add   ix,de
      pop   bc
      djnz  generateFlame

      ld    de,saferam1             ; prepare to draw flame to graph buffer
      ld    hl,plotsscreen+(0*12)+5

      ld    b,48-4                  ; draw flame row by row (omit bottom four rows)
drawFlame:
      push  bc
      ld    a,1                     ; invert dither bit each row
      xor   (iy+asm_flag1)
      ld    (iy+asm_flag1),a

      ld    c,2                     ; each row contains two bytes
drawRow:
      push  hl

      ld    b,8                     ; take eight array elements at a time
generateByte:
      ld    a,(de)                  ; grab an array element
      inc   de
      cp    32                      ; determine whether pixel should be lit, unlit or dithered
      jr    c,unlit
      cp    64
      jr    c,rotateBit
      cp    96
      jr    nc,rotateBit
      ld    a,b                     ; dither a pixel, depending on dither bit and current column
      add   a,(iy+asm_flag1)
      and   %00000001
      scf
      jr    z,rotateBit
unlit:
      and   a                       ; clear the carry bit
rotateBit:
      rl    h                       ; store the pixel
      djnz  generateByte

      ld    b,h
      pop   hl
      ld    (hl),b                  ; write the eight pixels to the graph buffer
      inc   hl
      dec   c
      jr    nz,drawRow              ; draw other half of row

      ld    bc,10                   ; move onto next row of graph buffer
      add   hl,bc
      pop   bc
      djnz  drawFlame               ; move onto next row of flame

      ld    a,1                     ; invert dither bit so that dithering on
      xor   (iy+asm_flag1)          ; next frame is out of phase with current
      ld    (iy+asm_flag1),a

      call  ionFastCopy             ; copy graph buffer to screen

      bcall(_getk)                  ; check for keypress
      or    a
      jp    z,animate               ; continue animating if nothing pressed

      ret                           ; exit program


sprTorch:                           ; torch sprite
.db %11111111, %11111111
.db %11111111, %11111111
.db %11111111, %11111111
.db %01111111, %11111110
.db %00111111, %11111100
.db %00001111, %11110000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000011, %11000000
.db %00000111, %11100000
.db %00001111, %11110000

.end
