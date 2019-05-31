code = $0801
sprites = $3E00
tables = $5000
charset = $3800

; misc registers
BorderColor     = $D020
BackgroundColor = $D021

; sprite registers
spritePointer = $07F8
spriteEnable = $D015

; screen stuff
screen = $0400
colors = $d800
rasterLine = $d012


; sprite position registers
SP0X = $D000
SP0Y = $D001
SP1X = $D002
SP1Y = $D003
SP2X = $D004
SP2Y = $D005
SP3X = $D006
SP3Y = $D007
SP4X = $D008
SP4Y = $D009
SP5X = $D00a
SP5Y = $D00b
SP6X = $D00c
SP6Y = $D00d
SP7X = $D00e
SP7Y = $D00f

SpriteH = $f8
SpriteE = $f9
SpriteL = $fa
SpriteO = $fb
SpriteD = $fc
SpriteB = $fd
SpriteI = $fe
SpriteR = $ff

lineHello = 0
lineScroll = 70
lineBirdie = 150

Temp         = $64
FrameCounter = $90
StartupDelay = $92
; Flag bits:
; 0 = stop Birdie text oscillation
Flags           = $FB
MusicPlayerVar1 = $FC ; Used by music player - don't touch
MusicPlayerVar2 = $FD ; Used by music player - don't touch

*=sprites
!binary "sprites/helodbir.prg",512,2

*= tables
sinTable1:
	!source "tables/sin1.dat"

sinTable2:
	!source "tables/sin2.dat"
	!source "tables/sin2.dat"

sinTable3:
	!source "tables/sin3.dat"

sinTable4:
	!source "tables/sin4.dat"

*=code
	; SYS2061
	!byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
start:
	jsr $e544		;clear screen
	jsr initSprites		;set up sprites
	jsr initMem		;set up memory mapping
	jsr initMisc		;
	sei
	jsr initIsr
	cli


main:
	jsr scrollText
	jmp main


initSprites:
	; setup sprite colors
	lda #$01
	sta $d025
	lda #$06
	sta $d026
	lda #$01
	sta $d027
	sta $d028
	sta $d029
	sta $d02a
	sta $d02b
	sta $d02c
	sta $d02d
	sta $d02e

	; control multicolor mode (1=multicolor, 0=hi-res)
	lda #%00000000
	sta $d01c

	; sprite expansion (1=double, 0=normal)
	lda #%00000000
	sta $d01d ; horizontal
	sta $d017 ; vertical
	
	; clear bit 8 of all sprite X positions
	lda #%00000000
	sta $d010

	rts


initMem:
	lda #%00010110
	sta $d018
	; $A000-$BFFF: RAM
	; $D000-$DFFF: I/O
	; $E000-$FFFF: RAM
	; No ROM
	lda #%00110101
	sta $01

	rts


initMisc:
	; 25 rows, text mode
	lda #$1b
	sta $d011
	lda #200
	sta StartupDelay

	rts


initIsr:
	; enable interrupts
	lda #$7f
	sta $dc0d
	sta $dd0d

	; clear/ack. interrupts
	lda $dc0d
	lda $dd0d

	; enable raster interrupts
	lda #$01
	sta $d01a

	lda #lineHello
	sta rasterLine
	jsr setInterruptHello

	rts

getFrameCounterInY:
	lda StartupDelay
	beq returnFrameCounter
	dec StartupDelay
	lda #0
	sta FrameCounter

returnFrameCounter:
	ldy FrameCounter

	rts


showHello:
	; Set sprite pointers
	lda #SpriteH
	sta spritePointer+0
	lda #SpriteE
	sta spritePointer+1
	lda #SpriteL
	sta spritePointer+2
	lda #SpriteL
	sta spritePointer+3
	lda #SpriteO
	sta spritePointer+4

	; move sprites
	lda #124
	sta SP0X
	lda #148
	sta SP1X
	lda #172
	sta SP2X
	lda #196
	sta SP3X
	lda #220
	sta SP4X

	jsr getFrameCounterInY
	lda sinTable1,y
	sta SP0Y
	sta SP1Y
	sta SP2Y
	sta SP3Y
	sta SP4Y

	; enable sprites
	lda #%00011111
	sta spriteEnable

	; set sprite priority (0=foreground, 1=background)
	lda #%11100000
	sta $d01b

	rts


scrollText:
	; Put some text
	jsr textMode
	ldx #$00
scrollNext:
	lda scrollerText,x
	sta screen+40*10,x
	lda #$01
	sta colors+40*10,x
	inx
	cpx #53
	bne scrollNext

	rts


showBirdie:
	; Set sprite pointers
	lda #SpriteB
	sta spritePointer+0
	lda #SpriteI
	sta spritePointer+1
	lda #SpriteR
	sta spritePointer+2
	lda #SpriteD
	sta spritePointer+3
	lda #SpriteI
	sta spritePointer+4
	lda #SpriteE
	sta spritePointer+5

	; move sprites
	lda #114
	sta SP0X
	lda #136
	sta SP1X
	lda #160
	sta SP2X
	lda #184
	sta SP3X
	lda #208
	sta SP4X
	lda #232
	sta SP5X

	lda #0
	sta Temp

	; Check flags
	lda Flags
	and #1
	bne setBirdeSpriteYPosition

	jsr getFrameCounterInY
	lda sinTable4,y
	sta Temp

	; adjust sine value
	; sinTable4 is setup to reach 0 at
	; * $20
	; * $60
	; * $A0
	; * $E0
	tya
	cmp #$20
	bcc setBirdeSpriteYPosition
	clc
	ror Temp
	cmp #$60
	bcc setBirdeSpriteYPosition
	clc
	ror Temp
	cmp #$A0
	bcc setBirdeSpriteYPosition
	clc
	ror Temp
	cmp #$E0
	bcc setBirdeSpriteYPosition
	clc
	ror Temp
	; stop oscillating Birdie text
	lda Flags
	ora #1
	sta Flags

setBirdeSpriteYPosition
	lda #230
	sbc Temp
	sta SP0Y
	sta SP1Y
	sta SP2Y
	sta SP3Y
	sta SP4Y
	sta SP5Y

	; enable sprites
	lda #%00111111
	sta spriteEnable

	; set sprite priority (0=foreground, 1=background)
	lda #%11000000
	sta $d01b

	rts


helloIsr:
	pha
	txa
	pha
	tya
	pha

	lda #$ff
	sta $d019

	jsr showHello

	inc FrameCounter

	lda #lineScroll
	sta rasterLine
	jsr setInterruptScroller

	pla
	tay
	pla
	tax
	pla

	rti


scrollerIsr:
	pha
	txa
	pha
	tya
	pha

	dec BorderColor

	lda #$ff
	sta $d019

	ldx #$ff
dl1:
	dex
	bne dl1
	
	jsr scrollText

	lda #lineBirdie
	sta rasterLine
	jsr setInterruptBirdie

	inc BorderColor

	pla
	tay
	pla
	tax
	pla

	rti


birdieIsr:
	pha
	txa
	pha
	tya
	pha

	inc BorderColor

	lda #$ff
	sta $d019

	jsr showBirdie
	
	lda #lineHello
	sta rasterLine
	jsr setInterruptHello

	dec BorderColor

	pla
	tay
	pla
	tax
	pla

	rti


setInterruptHello:
	lda #<helloIsr
	sta $fffe
	lda #>helloIsr
	sta $ffff

	rts

	
setInterruptBirdie:
	lda #<birdieIsr
	sta $fffe
	lda #>birdieIsr
	sta $ffff

	rts


setInterruptScroller:
	lda #<scrollerIsr
	sta $fffe
	lda #>scrollerIsr
	sta $ffff

	rts


scrollerText:
	!scr "ABCDEFGHIJKLMNOPQRSTUVXYZ abcdefghijklmnopqrstuvwxyz"


textMode:
	lda #%11001000
	sta $d016

	lda #%00011011
	sta $d011

	rts


graphicsMode:
	lda #%11011000
	sta $d016

	lda #%00111011
	sta $d011

	rts
