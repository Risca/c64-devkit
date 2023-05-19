; =============
; Include files
; =============
!source "source/regs.asm"

code = $0801 ; Default BASIC area
sprites = $3E00
tables = $5000
charset = $3800

char_H = $f8
char_E = $f9
char_L = $fa
char_O = $fb
char_D = $fc
char_B = $fd
char_I = $fe
char_R = $ff

lineBootstrap = 0
lineScroll = 60
lineBirdie = 150
lineBottomBorder = 249

ScrollOffset = $fe
SmoothScroll = $02
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
CurrBorderColor = $91


*=sprites
	!binary "sprites/helodbir.prg",512,2

*=tables
sinTable1:
	!source "tables/sin1.dat"

sinTable2:
	!source "tables/sin2.dat"
	!source "tables/sin2.dat"

sinTable3:
	!source "tables/sin3.dat"

sinTable4:
	!source "tables/sin4.dat"

music     = $6FF6 ; extracted from mandelvogel.sid @ $0A and $7C
musicPlay = $7003 ; extracted from mandelvogel.sid @ $0C
; Additional info from mandelvogel.sid:
; * Name: MandelVogel
; * Author: Hexeh
; * Released: 2019
; * has builtin music player
; * is C64 compatible
; * made for PAL systems
; * SID version: MOS6581
*=music
	; data begins at $7C, but first 2 bytes is the load addres ($6FF6)
	!binary "music/mandelvogel.sid",,$7e

rasterColor = $C000
*=rasterColor:
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

*=code  ; $0801
	; SYS2061, i.e. run machine code at 2061 ($080D)
	!byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
start:  ; I'm $080D :)
	jsr $e544    ;clear screen
	sei
	jsr initSprites ; set up sprites
	jsr initMem     ; set up memory mapping
	jsr initMisc    ; the rest
	jsr music
	jsr initIsr     ; oh, right, interrupts!
	cli

main:
	jsr textMode
	jmp main


initSprites:
	; setup sprite colors
	lda #$01
	sta SPRITE_MM0
	lda #$06
	sta SPRITE_MM1
	lda #$01
	sta SPRITE_0_COLOR
	sta SPRITE_1_COLOR
	sta SPRITE_2_COLOR
	sta SPRITE_3_COLOR
	sta SPRITE_4_COLOR
	sta SPRITE_5_COLOR
	sta SPRITE_6_COLOR
	sta SPRITE_7_COLOR

	; control multicolor mode (1=multicolor, 0=hi-res)
	lda #%00000000
	sta SPRITE_MM_ENABLE

	; sprite expansion (1=double, 0=normal)
	lda #%00000000
	sta SPRITE_X_EXPAND ; horizontal
	sta SPRITE_Y_EXPAND ; vertical

	; clear bit 8 of all sprite X positions
	lda #%00000000
	sta SPRITE_X_MSB

	rts


initMem:
	; [1:3]: A11-13 of charset (*2048)
	; [4:7]: A10-13 of screen RAM (*1024)
	; $1800-$1FFF: character memory (in text mode)
	; $0400-$07FF: Screen memory
	lda #%00010110
	sta VIC2_MEM_MAP

	; $A000-$BFFF: RAM
	; $D000-$DFFF: I/O
	; $E000-$FFFF: RAM
	; No ROM
	lda #%00110101
	sta PORT_CONFIG
	; no idea - removes artifacts on bottom border
	lda #$00
	sta $3FFF


	rts


initMisc:
	; 25 rows, text mode
	lda #$1b
	sta VIC_CONTROL_1
	lda #$02
	sta StartupDelayHigh
	lda #$58
	sta StartupDelayLow
	lda #00
	sta ScrollOffset
	sta SmoothScroll
	sta Flags
	lda #$0E
	sta CurrBorderColor

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
	ldy #1
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
	lda #char_H
	sta SPRITES+0
	lda #char_E
	sta SPRITES+1
	lda #char_L
	sta SPRITES+2
	lda #char_L
	sta SPRITES+3
	lda #char_O
	sta SPRITES+4

	; move sprites
	lda #124
	sta SPRITE_0_X
	lda #148
	sta SPRITE_1_X
	lda #172
	sta SPRITE_2_X
	lda #196
	sta SPRITE_3_X
	lda #220
	sta SPRITE_4_X

	jsr getFrameCounterInY
	lda sinTable1,y
	sta SPRITE_0_Y
	sta SPRITE_1_Y
	sta SPRITE_2_Y
	sta SPRITE_3_Y
	sta SPRITE_4_Y

	; enable sprites
	lda #%00011111
	sta SPRITE_ENABLE

	; set sprite priority (0=foreground, 1=background)
	lda #%11100000
	sta $d01b

	rts


scrollText:
	; Smooth scrolling
	lda SmoothScroll
	and #%00000111
	sta SmoothScroll
	cmp #07
	bne scrollDone

scrollText2:
	ldx #03 ;from
	ldy #02 ;to
scrollNext:
	; Write char and color to screen
	lda SCREEN+40*10,x
	sta SCREEN+40*10,y
	lda #01
	sta COLORS+40*10,y

	; increment counters
	inx
	iny

	; Out of viewport?
	cpx #37
	bmi scrollNext
	
	; update coarse scolling counter
	inc ScrollOffset
	ldx ScrollOffset
	cpx #128
	bmi scrollDrawLetter
	ldx #00
	stx ScrollOffset

scrollDrawLetter:
	; Grab new letter from text
	lda scrollerText,x
	; Store new letter to screen
	sta SCREEN+40*10,y

scrollDone:
	; update smooth scolling counter
	dec SmoothScroll
	rts


decreaseTransitionCounter:
	lda TransitionCounter
	beq transitionCounterAlreadyZero:
	dec TransitionCounter
transitionCounterAlreadyZero:
	rts


showBirdie:
	; Set sprite pointers
	lda #char_B
	sta SPRITES+0
	lda #char_I
	sta SPRITES+1
	lda #char_R
	sta SPRITES+2
	lda #char_D
	sta SPRITES+3
	lda #char_I
	sta SPRITES+4
	lda #char_E
	sta SPRITES+5

	; move sprites
	lda #114
	sta SPRITE_0_X
	lda #136
	sta SPRITE_1_X
	lda #160
	sta SPRITE_2_X
	lda #184
	sta SPRITE_3_X
	lda #208
	sta SPRITE_4_X
	lda #232
	sta SPRITE_5_X

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
	lda #0
	sta CurrBorderColor

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
	sta SPRITE_0_Y
	sta SPRITE_1_Y
	sta SPRITE_2_Y
	sta SPRITE_3_Y
	sta SPRITE_4_Y
	sta SPRITE_5_Y

	; enable sprites
	lda #%00111111
	sta SPRITE_ENABLE

	; set sprite priority (0=foreground, 1=background)
	lda #%11000000
	sta $d01b

	rts


bootstrapIsr:              ; [7]
	; self-modifying code - end of helloIsr will execute "ld{a,x,y} <reseta1+1>"
	; i.e. this replaces push + pop.
	sta reseta1+1      ; [4]
	stx resetx1+1      ; [4]
	sty resety1+1      ; [4]

	lda #<helloIsr     ; [4]
	sta ISR_LOW        ; [4]
	lda #>helloIsr     ; ]4]
	sta ISR_HIGH       ; [4]

	inc RASTER         ; [6]
	; hacky way to clear bit#7: asl writes the original value before shift
	asl INTREQ         ; [6]
	tsx                ; [2]
	; enable interrupts and perform nops until the next interrupt hits
	cli                ; [2]
        ; total cycles spent [51] (= 7 + 4*7 + 6*2 + 2*2)
	nop                ; [53]
	nop                ; [55]
	nop                ; [57]
	nop                ; [59]
	nop                ; [61]
	nop                ; [63]
	nop ; may be removed [65]. A raster line is at most 63 cycles long


helloIsr:                  ; [7]
	; we came here from bootstrapIsr
	txs ; restore stack  [2]
	; wait exactly 6 * (2+3) - 1 cycles so our raster line is in the border
	ldx #6             ; [2]
	dex                ; [2]
	bne *-1            ; [3/2]
        ; total cycles spent [40] (= 7 + 2*2 + 5*(2+3) + (2+2))

	; We're now in the borderlands

	; delay 5 lines: 2 + 62*5 - 1 + 2 + 2 = 5 * 63
	ldx #62            ; [2]
	dex                ; [2]
	bne *-1            ; [3/2]
	nop                ; [2]
	nop                ; [2]

	; delay 5 lines
	ldx #62            ; [2]
	dex                ; [2]
	bne *-1            ; [3/2]
	nop                ; [2]
	nop                ; [2]

	; delay 5 lines
	ldx #62            ; [2]
	dex                ; [2]
	bne *-1            ; [3/2]
	nop                ; [2]
	nop                ; [2]

	; cycles right now:  [40]
	ldx #0             ; [2]
nextRasterLine:
	txa                ; [2]
	adc FrameCounter   ; [3]
	and #$7F           ; [2]
	tay                ; [2]
	lda rasterColor,y  ; [4] (rasterColor is page aligned)
	sta BACKGROUND_COLOR;[4]
	sta BORDER_COLOR   ; [4]
	; cycle count is now [63] in first loop

	; wait 2+5*(2+3)-1 = [26] cycles
	ldy #5             ; [2]
	dey                ; [2]
	bne *-1            ; [3/2]

	nop                ; [2]
	nop                ; [2]
	cmp Temp           ; [3]

	inx                ; [2]
	txa                ; [2]
	cmp #20            ; [2]
	bne nextRasterLine ; [3/2]
	; raster loop takes  [63] cycles
	; we should be at    [41] cycles of current line when exiting the loop

	nop                ; [2]
	nop                ; [2]
	nop                ; [2]
	nop                ; [2]
	nop                ; [2]
	nop                ; [2]

	lda CurrBorderColor; [4]
	sta BORDER_COLOR   ; [4]
	lda #0             ; [2]
	sta BACKGROUND_COLOR;[4]

	jsr showHello

	inc FrameCounter
	jsr decreaseStartupDelay

	jsr setInterruptScroller

	lda #$ff
	sta INTREQ

	; "pop" axy from the stack
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
	sta INTREQ

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
	sta INTREQ

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
	sta INTREQ

	lda Flags
	and #2
	beq skipHack

	; Set 24 rows
	lda VIC_CONTROL_1
	and #$F7
	sta VIC_CONTROL_1
skipHack:

	jsr musicPlay
	jsr setInterruptBootstrap

	; Set 25 rows (revert hack in before)
	lda VIC_CONTROL_1
	ora #$08
	sta VIC_CONTROL_1

	pla
	tay
	pla
	tax
	pla

	rti


setInterruptBootstrap:
	lda #lineBootstrap
	sta RASTER
	lda #<bootstrapIsr
	sta ISR_LOW
	lda #>bootstrapIsr
	sta ISR_HIGH

	rts


setInterruptBirdie:
	lda #lineBirdie
	sta RASTER
	lda #<birdieIsr
	sta ISR_LOW
	lda #>birdieIsr
	sta ISR_HIGH

	rts


setInterruptScroller:
	lda #lineScroll
	sta RASTER
	lda #<scrollerIsr
	sta ISR_LOW
	lda #>scrollerIsr
	sta ISR_HIGH

	rts


setInterruptBottomBorder
	lda #lineBottomBorder
	sta RASTER
	lda #<bottomBorderIsr
	sta ISR_LOW
	lda #>bottomBorderIsr
	sta ISR_HIGH

	rts


scrollerText:
	!scr "                         This is a n00b C64 demo           We are really proud of it (and super jittery from no sleep!)                              Created @ Birdie 29 by Risca and FireArrow. Music by Hexeh                             "


textMode:
	lda #%11001000
	adc SmoothScroll
	sta VIC_CONTROL_2

	lda #%00011011
	sta VIC_CONTROL_1

	rts


graphicsMode:
	lda #%11011000
	sta VIC_CONTROL_2

	lda #%00111011
	sta VIC_CONTROL_1

	rts
