code = $0801
sprites = $3E00
tables = $5000
charset = $3800
music = $6FF6
musicPlay = $7003

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

lineBootstrap = 0
lineScroll = 70
lineBirdie = 150
lineBottomBorder = 249

Temp         = $64
FrameCounter = $90
StartupDelayHigh = $92
StartupDelayLow  = $93
TransitionCounter = $3

; Flag bits:
; 0 = stop Birdie text oscillation
; 1 = remove top/bottom border
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

*=music
	!binary "music/mandelvogel.sid",,$7e

rasterColor:
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00
	!byte $09,$02,$08,$0a,$0f,$07,$01,$07,$0f,$0a,$08,$02,$09,$00
	!byte $06,$04,$0e,$05,$03,$0d,$01,$0d,$03,$05,$0e,$04,$06,$00

*=code
	; SYS2061
	!byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
start:
	jsr $e544		;clear screen
	sei
	jsr initSprites		;set up sprites
	jsr initMem		;set up memory mapping
	jsr initMisc		;
	jsr music
	jsr initIsr
	cli

main:
	jsr textMode
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
	; no idea - removes artifacts on bottom border
	lda #$00
	sta $3FFF

	rts


initMisc:
	; 25 rows, text mode
	lda #$1b
	sta $d011
	lda #$02
	sta StartupDelayHigh
	lda #$58
	sta StartupDelayLow
	lda #0
	sta Flags

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

	jsr setInterruptBootstrap

	rts


getFrameCounterInY:
	lda StartupDelayLow
	bne zeroFrameCounter
	lda StartupDelayHigh
	beq returnFrameCounter
zeroFrameCounter:
	ldy #0
	sty FrameCounter
returnFrameCounter:
	ldy FrameCounter

	rts


decreaseStartupDelay:
	lda StartupDelayLow
	beq decreaseDelayHigh ; low == 0 -> decrease high byte
	dec StartupDelayLow
	jmp decreaseDelayDone
decreaseDelayHigh:
	lda StartupDelayHigh
	beq decreaseDelayDone ; both high:low == 0:0 -> done
	dec StartupDelayHigh
	dec StartupDelayLow
decreaseDelayDone:

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
	cpx #55
	bne scrollNext

	rts


decreaseTransitionCounter:
	lda TransitionCounter
	beq transitionCounterAlreadyZero:
	dec TransitionCounter
transitionCounterAlreadyZero:
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

	; Check flags
	lda Flags
	and #1
	beq noTransitionEffect

	jsr decreaseTransitionCounter

	lda TransitionCounter
	cmp #25
	bcs noTransitionEffect
	lda Flags
	ora #2 ; remove border
	sta Flags
calculateSpritePositionInBorder
	lda #$FF
	clc
	sbc TransitionCounter
	jmp setBirdieSpriteYPos
noTransitionEffect:

	lda #0
	sta Temp

	lda Flags
	and #1
	bne calculateSpritePositionAboveBorder

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
	bcc calculateSpritePositionAboveBorder
	clc
	ror Temp
	cmp #$60
	bcc calculateSpritePositionAboveBorder
	clc
	ror Temp
	cmp #$A0
	bcc calculateSpritePositionAboveBorder
	clc
	ror Temp
	cmp #$E0
	bcc calculateSpritePositionAboveBorder
	clc
	ror Temp
	; stop oscillating Birdie text
	lda Flags
	ora #1
	sta Flags
	lda #$FF
	sta TransitionCounter

calculateSpritePositionAboveBorder:
	lda #230
	sbc Temp

setBirdieSpriteYPos:
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


bootstrapIsr:
	; self-modifying code - end of helloIsr will execute "ld{a,x,y} <reseta1+1>"
	sta reseta1+1
	stx resetx1+1
	sty resety1+1

	lda #<helloIsr
	ldx #>helloIsr

	sta $fffe
	stx $ffff
	inc rasterLine
	asl $d019
	tsx
	; enable interrupts and perform nops until the next interrupt hits
	cli
	nop
	nop
	nop
	nop
	nop
	nop
	nop


helloIsr:
	txs ; we came here from bootstrapIsr, restore stack pointer

	ldx #6 ; wait exactly 6 * (2+3) cycles so our raster line is in the border
	dex
	bne *-1 ; hacky syntax

	; delay 5 lines
	ldx #63
	dex
	bne *-1

	; delay 5 lines
	ldx #63
	dex
	bne *-1

	; delay 5 lines
	ldx #63
	dex
	bne *-1

	ldx #0
nextRasterLine:
	txa
	adc FrameCounter
	and #$7F
	tay
	lda rasterColor,y
	sta BackgroundColor
	sta BorderColor

	ldy #5
rasterDelayLoop:
	dey
	bne rasterDelayLoop

	nop
	nop
	cmp $EA

	inx
	txa
	cmp #20
	bne nextRasterLine

	nop
	nop

	lda #0
	sta BorderColor
	sta BackgroundColor

	jsr showHello

	inc FrameCounter
	jsr decreaseStartupDelay

	jsr setInterruptScroller

	lda #$ff
	sta $d019

reseta1:
	lda #$00
resetx1:
	ldx #$00
resety1:
	ldy #$00

	rti


scrollerIsr:
	pha
	txa
	pha
	tya
	pha

	lda #$ff
	sta $d019

	jsr scrollText

	jsr setInterruptBirdie

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

	lda #$ff
	sta $d019

	jsr showBirdie
	jsr musicPlay

	jsr setInterruptBottomBorder

	pla
	tay
	pla
	tax
	pla

	rti


bottomBorderIsr:
	pha
	txa
	pha
	tya
	pha

	lda #$ff
	sta $d019

	lda Flags
	and #2
	beq skipHack

	; Set 24 rows
	lda $D011
	and #$F7
	sta $D011
skipHack:

	jsr musicPlay
	jsr setInterruptBootstrap

	; Set 25 rows (revert hack in before)
	lda $D011
	ora #$08
	sta $D011

	pla
	tay
	pla
	tax
	pla

	rti


setInterruptBootstrap:
	lda #lineBootstrap
	sta rasterLine
	lda #<bootstrapIsr
	sta $fffe
	lda #>bootstrapIsr
	sta $ffff

	rts


setInterruptBirdie:
	lda #lineBirdie
	sta rasterLine
	lda #<birdieIsr
	sta $fffe
	lda #>birdieIsr
	sta $ffff

	rts


setInterruptScroller:
	lda #lineScroll
	sta rasterLine
	lda #<scrollerIsr
	sta $fffe
	lda #>scrollerIsr
	sta $ffff

	rts


setInterruptBottomBorder
	lda #lineBottomBorder
	sta rasterLine
	lda #<bottomBorderIsr
	sta $fffe
	lda #>bottomBorderIsr
	sta $ffff

	rts


scrollerText:
	!scr "DEMO @ Birdie 29 by Risca and FireArrow. Music by Hexeh"


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
