; Theory:
; If we
; * trigger a raster interrupt just before the end of line 24,
; * switch to 25 line mode,
; * delay a bit to get past end of line 24,
; * then switch back to 24 line mode
; the VIC will "forget" to clear the bottom border, and also
; the top border.
*=$0801
	!byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
start:
	; disable interrupt from CIA controller
	sei
	lda #$7F
	sta $DC0D

	lda #<irq1
	sta $0314
	lda #>irq1
	sta $0315

	; set raster line to trigger interrupt on
	lda #$FA
	sta $D012
	lda #$1B ; default = 1b
	sta $D011

	; clear up artifacts?
	lda #$00
	sta $3FFF

	; acknowledge interrupts
	lda $DC0D
	lda #$FF
	sta $D019

	; enable raster interrupt
	lda #$01
	sta $D01A

	cli

_waitSpace
	lda $DC01
	and #$10
	bne _waitSpace

	jmp $FCE2

; variables
BorderColor
	!byte 0
BorderColor_counter
	!byte 60
BorderColor_counterResetValue
	!byte 60

irq1:
	; set 25 rows
	lda $D011
	and #$F7
	sta $D011

	; adjust background color
	dec BorderColor_counter
	bne noChange
	lda BorderColor_counterResetValue
	sta BorderColor_counter
	inc BorderColor
noChange:
	lda BorderColor
	sta $D020

	ldx #$10
dummyDelay:
	dex
	bne dummyDelay

	; set 24 rows
	lda $D011
	ora #$08
	sta $D011

	; restore border color
	lda #$0E
	sta $D020

	lda #$FF
	sta $D019

	jmp $EA81

