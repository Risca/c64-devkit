	*=$0801
	!byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00

	*=$0810

	; Load timer with 0x0265
	lda #$65
	sta $dd04
	lda #$02
	sta $dd05

	; Make timer interrupt jump to our nmi routine below
	lda #<nmi
	sta $0318
	lda #>nmi
	sta $0319

	; Enable interrups on timer A, and reset it
	lda #$1
	sta $dd0e
	lda #$81
	sta $dd0d

	lda #3
	sta $d020
	sta $d021

	ldx #0

loop:
	lda text,x
	sta $0400+40*12+14,x
	inx
	cpx #11
	bne loop

wait:
	jmp wait

text:
	!scr "hello world"

; NMI interrupt
nmi:
	inc $d020
	pha
	lda $dd0d
	pla
	rti

