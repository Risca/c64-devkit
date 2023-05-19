; ==============
; 6510 registers
; ==============
PORT_DIRECTION    = $0000
PORT_CONFIG       = $0001

; screen stuff
SCREEN            = $0400 ; (depends on VIC2_MEM_MAP)
SPRITES           = $07F8
COLORS            = $D800

ISR_LOW           = $FFFE
ISR_HIGH          = $FFFF

; ===============
; VIC-2 registers
; ===============

; sprite position registers
SPRITE_0_X        = $D000
SPRITE_0_Y        = $D001
SPRITE_1_X        = $D002
SPRITE_1_Y        = $D003
SPRITE_2_X        = $D004
SPRITE_2_Y        = $D005
SPRITE_3_X        = $D006
SPRITE_3_Y        = $D007
SPRITE_4_X        = $D008
SPRITE_4_Y        = $D009
SPRITE_5_X        = $D00a
SPRITE_5_Y        = $D00b
SPRITE_6_X        = $D00c
SPRITE_6_Y        = $D00d
SPRITE_7_X        = $D00e
SPRITE_7_Y        = $D00f
SPRITE_X_MSB      = $D010
VIC_CONTROL_1     = $D011
RASTER            = $D012
SPRITE_ENABLE     = $D015
VIC_CONTROL_2     = $D016
SPRITE_Y_EXPAND   = $D017
VIC2_MEM_MAP      = $D018
INTREQ            = $D019
SPRITE_MM_ENABLE  = $D01C
SPRITE_X_EXPAND   = $D01D
BORDER_COLOR      = $D020
BACKGROUND_COLOR  = $D021
SPRITE_MM0        = $D025
SPRITE_MM1        = $D026
SPRITE_0_COLOR    = $D027
SPRITE_1_COLOR    = $D028
SPRITE_2_COLOR    = $D029
SPRITE_3_COLOR    = $D02a
SPRITE_4_COLOR    = $D02b
SPRITE_5_COLOR    = $D02c
SPRITE_6_COLOR    = $D02d
SPRITE_7_COLOR    = $D02e

