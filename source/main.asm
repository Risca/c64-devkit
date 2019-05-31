code = $0801
sprites = $3E00

; misc registers
BorderColor     = $D020
BackgroundColor = $D021

; sprite registers
spritePointer = $07F8
spriteEnable = $D015

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

line1 = 0
line2 = 155

*=sprites
!binary "sprites/helodbir.prg",512,2

*=code
	; SYS2061
	!byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
start:
	jsr $e544
	jsr initSprites
	jsr initMem
	jsr initMisc
	sei
	jsr initIsr
	cli

_waitSpace
	lda $DC01
	and #$10
	bne _waitSpace

	jmp $FCE2

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
	lda #%00011110
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

	lda #line1
	sta $d012

	lda #<helloIsr
	sta $fffe
	lda #>helloIsr
	sta $ffff

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

	lda #100
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

	lda #160
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

	lda #line2
	sta $d012

	lda #<birdieIsr
	sta $fffe
	lda #>birdieIsr
	sta $ffff

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
	
	lda #line1
	sta $d012

	lda #<helloIsr
	sta $fffe
	lda #>helloIsr
	sta $ffff

	dec BorderColor

	pla
	tay
	pla
	tax
	pla

	rti
	
