#!/bin/bash

# code written by Ahmad Byagowi for demonstration purposes of a SYS INFO demon for the MiSTer using a SSD1327 OLED module over the i2c bus 
# Please not the OLED I2C address was modified to 0x3D. For a default configuration please change it to 0x3c

I2CBUS=2
DEVADDR=0x3D #defualt is 0x3c

corenamefile="/tmp/CORENAME"

TEMP_DEVADDR=0x4F
AD7414_VAL=0x00
AD7414_CONF=0x01
AD7414_T_HIGH=0x02
AD7414_T_LOW=0x03

AD7414_DEF_CONF=0x40

#set default configuration
function init_temp_sensor_default_config(){
i2cset -y $I2CBUS $TEMP_DEVADDR $AD7414_CONF $AD7414_DEF_CONF
}

#read temperature value register 
function read_temperature(){
local raw_val=$(($(i2cget -y $I2CBUS $TEMP_DEVADDR $AD7414_VAL w)))
local lo_val=$(("$raw_val">>14))
local hi_val=$(("$raw_val"&0xff))
local code_val=$(("$lo_val"|$(("$hi_val"<<2))))
if [ $(( "$hi_val" & 0x80)) -ne 0 ]; then
  code_val=$(($code_val - 512))
fi
printf "%.2f C" $(echo $code_val / 4 | bc -l)
}


declare -A frameBuffer

declare -A tempBuff

# Font 8x8
# Font starts with ASCII "0x20/32 (Space)
font_height=8
font_width=8
font=(
"0x00" "0x00" "0x00" "0x00" "0x00" "0x00" "0x00" "0x00"  # Space
"0x00" "0x00" "0x00" "0x00" "0x5F" "0x00" "0x00" "0x00"  # !
"0x00" "0x00" "0x00" "0x03" "0x00" "0x03" "0x00" "0x00"  # "
"0x00" "0x24" "0x7E" "0x24" "0x24" "0x7E" "0x24" "0x00"  # #
"0x00" "0x2E" "0x2A" "0x7F" "0x2A" "0x3A" "0x00" "0x00"  # $
"0x00" "0x46" "0x26" "0x10" "0x08" "0x64" "0x62" "0x00"  # %
"0x00" "0x20" "0x54" "0x4A" "0x54" "0x20" "0x50" "0x00"  # &
"0x00" "0x00" "0x00" "0x04" "0x02" "0x00" "0x00" "0x00"  # '
"0x00" "0x00" "0x00" "0x3C" "0x42" "0x00" "0x00" "0x00"  # (
"0x00" "0x00" "0x00" "0x42" "0x3C" "0x00" "0x00" "0x00"  # )
"0x00" "0x10" "0x54" "0x38" "0x54" "0x10" "0x00" "0x00"  # *
"0x00" "0x10" "0x10" "0x7C" "0x10" "0x10" "0x00" "0x00"  # +
"0x00" "0x00" "0x00" "0x80" "0x60" "0x00" "0x00" "0x00"  # "
"0x00" "0x10" "0x10" "0x10" "0x10" "0x10" "0x00" "0x00"  # -
"0x00" "0x00" "0x00" "0x60" "0x60" "0x00" "0x00" "0x00"  # .
"0x00" "0x40" "0x20" "0x10" "0x08" "0x04" "0x00" "0x00"  # /
"0x3C" "0x62" "0x52" "0x4A" "0x46" "0x3C" "0x00" "0x00"  # 0
"0x44" "0x42" "0x7E" "0x40" "0x40" "0x00" "0x00" "0x00"  # 1
"0x64" "0x52" "0x52" "0x52" "0x52" "0x4C" "0x00" "0x00"  # 2
"0x24" "0x42" "0x42" "0x4A" "0x4A" "0x34" "0x00" "0x00"  # 3
"0x30" "0x28" "0x24" "0x7E" "0x20" "0x20" "0x00" "0x00"  # 4
"0x2E" "0x4A" "0x4A" "0x4A" "0x4A" "0x32" "0x00" "0x00"  # 5
"0x3C" "0x4A" "0x4A" "0x4A" "0x4A" "0x30" "0x00" "0x00"  # 6
"0x02" "0x02" "0x62" "0x12" "0x0A" "0x06" "0x00" "0x00"  # 7
"0x34" "0x4A" "0x4A" "0x4A" "0x4A" "0x34" "0x00" "0x00"  # 8
"0x0C" "0x52" "0x52" "0x52" "0x52" "0x3C" "0x00" "0x00"  # 9
"0x00" "0x00" "0x00" "0x48" "0x00" "0x00" "0x00" "0x00"  # :
"0x00" "0x00" "0x80" "0x64" "0x00" "0x00" "0x00" "0x00"  # ;
"0x00" "0x00" "0x10" "0x28" "0x44" "0x00" "0x00" "0x00"  # <
"0x00" "0x28" "0x28" "0x28" "0x28" "0x28" "0x00" "0x00"  # =
"0x00" "0x00" "0x44" "0x28" "0x10" "0x00" "0x00" "0x00"  # >
"0x00" "0x04" "0x02" "0x02" "0x52" "0x0A" "0x04" "0x00"  # ?
"0x00" "0x3C" "0x42" "0x5A" "0x56" "0x5A" "0x1C" "0x00"  # @
"0x7C" "0x12" "0x12" "0x12" "0x12" "0x7C" "0x00" "0x00"  # A
"0x7E" "0x4A" "0x4A" "0x4A" "0x4A" "0x34" "0x00" "0x00"  # B
"0x3C" "0x42" "0x42" "0x42" "0x42" "0x24" "0x00" "0x00"  # C
"0x7E" "0x42" "0x42" "0x42" "0x24" "0x18" "0x00" "0x00"  # D
"0x7E" "0x4A" "0x4A" "0x4A" "0x4A" "0x42" "0x00" "0x00"  # E
"0x7E" "0x0A" "0x0A" "0x0A" "0x0A" "0x02" "0x00" "0x00"  # F
"0x3C" "0x42" "0x42" "0x52" "0x52" "0x34" "0x00" "0x00"  # G
"0x7E" "0x08" "0x08" "0x08" "0x08" "0x7E" "0x00" "0x00"  # H
"0x00" "0x42" "0x42" "0x7E" "0x42" "0x42" "0x00" "0x00"  # I
"0x30" "0x40" "0x40" "0x40" "0x40" "0x3E" "0x00" "0x00"  # J
"0x7E" "0x08" "0x08" "0x14" "0x22" "0x40" "0x00" "0x00"  # K
"0x7E" "0x40" "0x40" "0x40" "0x40" "0x40" "0x00" "0x00"  # L
"0x7E" "0x04" "0x08" "0x08" "0x04" "0x7E" "0x00" "0x00"  # M
"0x7E" "0x04" "0x08" "0x10" "0x20" "0x7E" "0x00" "0x00"  # N
"0x3C" "0x42" "0x42" "0x42" "0x42" "0x3C" "0x00" "0x00"  # O
"0x7E" "0x12" "0x12" "0x12" "0x12" "0x0C" "0x00" "0x00"  # P
"0x3C" "0x42" "0x52" "0x62" "0x42" "0x3C" "0x00" "0x00"  # Q
"0x7E" "0x12" "0x12" "0x12" "0x32" "0x4C" "0x00" "0x00"  # R
"0x24" "0x4A" "0x4A" "0x4A" "0x4A" "0x30" "0x00" "0x00"  # S
"0x02" "0x02" "0x02" "0x7E" "0x02" "0x02" "0x02" "0x00"  # T
"0x3E" "0x40" "0x40" "0x40" "0x40" "0x3E" "0x00" "0x00"  # U
"0x1E" "0x20" "0x40" "0x40" "0x20" "0x1E" "0x00" "0x00"  # V
"0x3E" "0x40" "0x20" "0x20" "0x40" "0x3E" "0x00" "0x00"  # W
"0x42" "0x24" "0x18" "0x18" "0x24" "0x42" "0x00" "0x00"  # X
"0x02" "0x04" "0x08" "0x70" "0x08" "0x04" "0x02" "0x00"  # Y
"0x42" "0x62" "0x52" "0x4A" "0x46" "0x42" "0x00" "0x00"  # Z
"0x00" "0x00" "0x7E" "0x42" "0x42" "0x00" "0x00" "0x00"  # [
"0x00" "0x04" "0x08" "0x10" "0x20" "0x40" "0x00" "0x00"  # <backslash>
"0x00" "0x00" "0x42" "0x42" "0x7E" "0x00" "0x00" "0x00"  # ]
"0x00" "0x08" "0x04" "0x7E" "0x04" "0x08" "0x00" "0x00"  # ^
"0x80" "0x80" "0x80" "0x80" "0x80" "0x80" "0x80" "0x00"  # _
"0x3C" "0x42" "0x99" "0xA5" "0xA5" "0x81" "0x42" "0x3C"  # `
"0x00" "0x20" "0x54" "0x54" "0x54" "0x78" "0x00" "0x00"  # a
"0x00" "0x7E" "0x48" "0x48" "0x48" "0x30" "0x00" "0x00"  # b
"0x00" "0x00" "0x38" "0x44" "0x44" "0x44" "0x00" "0x00"  # c
"0x00" "0x30" "0x48" "0x48" "0x48" "0x7E" "0x00" "0x00"  # d
"0x00" "0x38" "0x54" "0x54" "0x54" "0x48" "0x00" "0x00"  # e
"0x00" "0x00" "0x00" "0x7C" "0x0A" "0x02" "0x00" "0x00"  # f
"0x00" "0x18" "0xA4" "0xA4" "0xA4" "0xA4" "0x7C" "0x00"  # g
"0x00" "0x7E" "0x08" "0x08" "0x08" "0x70" "0x00" "0x00"  # h
"0x00" "0x00" "0x00" "0x48" "0x7A" "0x40" "0x00" "0x00"  # i
"0x00" "0x00" "0x40" "0x80" "0x80" "0x7A" "0x00" "0x00"  # j
"0x00" "0x7E" "0x18" "0x24" "0x40" "0x00" "0x00" "0x00"  # k
"0x00" "0x00" "0x00" "0x3E" "0x40" "0x40" "0x00" "0x00"  # l
"0x00" "0x7C" "0x04" "0x78" "0x04" "0x78" "0x00" "0x00"  # m
"0x00" "0x7C" "0x04" "0x04" "0x04" "0x78" "0x00" "0x00"  # n
"0x00" "0x38" "0x44" "0x44" "0x44" "0x38" "0x00" "0x00"  # o
"0x00" "0xFC" "0x24" "0x24" "0x24" "0x18" "0x00" "0x00"  # p
"0x00" "0x18" "0x24" "0x24" "0x24" "0xFC" "0x80" "0x00"  # q
"0x00" "0x00" "0x78" "0x04" "0x04" "0x04" "0x00" "0x00"  # r
"0x00" "0x48" "0x54" "0x54" "0x54" "0x20" "0x00" "0x00"  # s
"0x00" "0x00" "0x04" "0x3E" "0x44" "0x40" "0x00" "0x00"  # t
"0x00" "0x3C" "0x40" "0x40" "0x40" "0x3C" "0x00" "0x00"  # u
"0x00" "0x0C" "0x30" "0x40" "0x30" "0x0C" "0x00" "0x00"  # v
"0x00" "0x3C" "0x40" "0x38" "0x40" "0x3C" "0x00" "0x00"  # w
"0x00" "0x44" "0x28" "0x10" "0x28" "0x44" "0x00" "0x00"  # x
"0x00" "0x1C" "0xA0" "0xA0" "0xA0" "0x7C" "0x00" "0x00"  # y
"0x00" "0x44" "0x64" "0x54" "0x4C" "0x44" "0x00" "0x00"  # z
"0x00" "0x08" "0x08" "0x76" "0x42" "0x42" "0x00" "0x00"  # {
"0x00" "0x00" "0x00" "0x7E" "0x00" "0x00" "0x00" "0x00"  # |
"0x00" "0x42" "0x42" "0x76" "0x08" "0x08" "0x00" "0x00"  # }
"0x00" "0x00" "0x04" "0x02" "0x04" "0x02" "0x00" "0x00"  # ~
)


function display_off() {
i2cset -y $I2CBUS $DEVADDR 0x00 0xAB # Set Display offset
i2cset -y $I2CBUS $DEVADDR 0x00 0x00 # Set Display offset
i2cset -y $I2CBUS $DEVADDR 0x00 0xAE # Display OFF (sleep mode)
sleep 0.1
}

function init_display() {
i2cset -y $I2CBUS $DEVADDR 0x00 0xFD 0x01 0x12 i # Unlock
i2cset -y $I2CBUS $DEVADDR 0x00 0xAE 0x00 i  # Display off
i2cset -y $I2CBUS $DEVADDR 0x00 0x15 0x00 0x3F i  # Set Column address
i2cset -y $I2CBUS $DEVADDR 0x00 0x75 0x00 0x7F i  # Set Row address
i2cset -y $I2CBUS $DEVADDR 0x00 0xA1 0x00  i  # Set Start line
i2cset -y $I2CBUS $DEVADDR 0x00 0xA2 0x00 i  # Set Display offset
i2cset -y $I2CBUS $DEVADDR 0x00 0xA0 0x14 0x11 i  # Set Display offset
i2cset -y $I2CBUS $DEVADDR 0x00 0xA8 0x7F i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xAB 0x01 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xB1 0xE2 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xB3 0x91 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xBC 0x08 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xBE 0x07 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xB6 0x01 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xD5 0x62 i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xb8 0x0f 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x10 0x18 0x20 0x2f 0x38 0x3f i  
i2cset -y $I2CBUS $DEVADDR 0x00 0xB9  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0x81 0x7F i  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xA4 # 
i2cset -y $I2CBUS $DEVADDR 0x00 0x2E  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xAF  # 
i2cset -y $I2CBUS $DEVADDR 0x00 0xCA 0x3F i  # S
i2cset -y $I2CBUS $DEVADDR 0x00 0xA0 0x51 0x42 i  # 

}

function display_on() {
i2cset -y $I2CBUS $DEVADDR 0x00 0xAB  # Display ON (normal mode)
i2cset -y $I2CBUS $DEVADDR 0x00 0x01  # Set Display offset
i2cset -y $I2CBUS $DEVADDR 0x00 0xAF  # Set Display offset

sleep 0.001
}

function reset_cursor() {
   i2cset -y $I2CBUS $DEVADDR 0x00 0x15 0x00 0x3F 0x75 0x00 0x7F i 
}

function set_cursor() {
  i2cset -y $I2CBUS $DEVADDR 0x00 0x15 $(( ${1} >> 1 ))  0x3F 0x75 ${2} 0x7F i 
}

function set_WriteZone() {
  i2cset -y $I2CBUS $DEVADDR 0x00 0x15 ${1} ${2} 0x75 ${3} ${4} i 
}

function frameToOLED(){
  echo $(( $(( {$1}/2 )) + $(( {$2}*64 )) ))
}


function ord() {
  # Get ASCII Value from Character
  local chardec=$(LC_CTYPE=C printf '%d' "'$1")
  [ "${chardec}" -eq 0 ] && chardec=32             # Manual Mod for " " (Space)
  echo ${chardec}
  #printf '%d' "'$1"
  #LC_CTYPE=C printf '%d' "'$1"
}

function showtext() {
  local a=0; local b=0; local achar=0; local charp=0; local charout="";
  local text=${1}
  local textlen=${#text}
  #echo "Textlen: ${textlen}"
  for (( a=0; a<${textlen}; a++ )); do
    achar="`ord ${text:${a}:1}`"               # get the ASCII Code
    let charp=(achar-32)*${font_width}         # calculate first byte in font array
    charout=""
    for (( b=0; b<${font_width}; b++ )); do    # character loop
      charout="${charout} ${font[charp+b]}"    # build character out of single values
    done
    # echo "${a}: ${text:${a}:1} -> ${achar} -> ${charp} -> ${charout}"
  i2cset -y $I2CBUS $DEVADDR 0x40 ${charout} i                      # send character bytes to display
  done
}

function loadBuffer(){
i2cset -y $I2CBUS $DEVADDR 0x00 0x15 0x00 0x3F 0x75 0x00 0x7F i 
for ((i=0;i<256;i++)) do
  for ((j=0;j<32;j++)) do
    local pointer=$(( $j+(($i<<5)) ))
    tempBuff[$j]=${frameBuffer[$pointer]}
  done
   i2cset -y $I2CBUS $DEVADDR 0x40 ${tempBuff[0]} ${tempBuff[1]} ${tempBuff[2]} ${tempBuff[3]} ${tempBuff[4]} ${tempBuff[5]} ${tempBuff[6]} ${tempBuff[7]} ${tempBuff[8]} ${tempBuff[9]} ${tempBuff[10]} ${tempBuff[11]} ${tempBuff[12]} ${tempBuff[13]} ${tempBuff[14]} ${tempBuff[15]} ${tempBuff[16]} ${tempBuff[17]} ${tempBuff[18]} ${tempBuff[19]} ${tempBuff[20]} ${tempBuff[21]} ${tempBuff[22]} ${tempBuff[23]} ${tempBuff[24]} ${tempBuff[25]} ${tempBuff[26]} ${tempBuff[27]} ${tempBuff[28]} ${tempBuff[29]} ${tempBuff[30]} ${tempBuff[31]} i

done
}

function blankBuffer(){
for ((i=0;i<64;i++)) do
    for ((j=0;j<128;j++)) do
  local pointer=$(( $i+(($j<<6)) ))
        frameBuffer[$pointer]=0x00
    done
done
}


function fillBuffer(){
for ((i=0;i<64;i++)) do
    for ((j=0;j<128;j++)) do
  local pointer=$(( $i+(($j<<6)) ))
        frameBuffer[$pointer]=0xFF
    done
done
}

function drawPixel(){ #startX startY color instant 
local pix_addr=$(( $(( $1 >> 1 )) + $(( $2 << 6 )) ))
local pix_val=0
local input=$(($3 & 0xFF))
if [ $(( $1 % 2 )) -eq 0 ]; then
  pix_val=$(( $(( ${frameBuffer[$pix_addr]} & 0x0F )) | $(( $input << 4 )) ))
frameBuffer[$pix_addr]=$pix_val
else
  pix_val=$(( $(( ${frameBuffer[$pix_addr]} & 0xF0 )) | $input ))
frameBuffer[$pix_addr]=$pix_val
fi
if [ $4 -eq 1 ]; then
set_cursor $1 $2
i2cset -y $I2CBUS $DEVADDR 0x40 $pix_val i
fi
}

function drawRect(){ #startX startY endX endY color instant

local xMax=$(( $1 > $3 ? $1 : $3 ))
local xMin=$(( $1 > $3 ? $3 : $1 ))
local yMax=$(( $2 > $4 ? $2 : $4 ))
local yMin=$(( $2 > $4 ? $4 : $2 ))

for ((j=yMin;j<yMax;j++)) do
    for ((i=xMin;i<xMax;i++)) do
       drawPixel $i $j $5 $6
    done
done
}

function drawLine(){ #startX startY endX endY color instant

local xMax=$(( $1 > $3 ? $1 : $3 ))
local xMin=$(( $1 > $3 ? $3 : $1 ))
local yMax=$(( $2 > $4 ? $2 : $4 ))
local yMin=$(( $2 > $4 ? $4 : $2 ))

local xDelta=$(( $xMax - $xMin ))
local yDelta=$(( $yMax - $yMin ))

local xSign=$(( $1 > $3 ? -1 : 1 ))
local ySign=$(( $2 > $4 ? -1 : 1 ))

if [ $xDelta -gt $yDelta ];then
  for ((t=0;t<xDelta;t++)) do
     if [ $xDelta -ne 0 ]; then 
        drawPixel $(( $1 + $(( $t * $xSign )) )) $(( $2 + $(( $(( $(( $(( $t * $ySign )) *  $yDelta )) / $xDelta  )) )) )) $5 $6
     else
        drawPixel $(( $1 + $(( $t * $xSign )) )) $2 $5 $6
     fi   
  done
else
  for ((t=0;t<yDelta;t++)) do
     if [ $yDelta -ne 0 ]; then 
        drawPixel $(( $1 + $(( $(( $(( $(( $t * $xSign )) *  $xDelta )) / $yDelta  )) )) )) $(( $2 + $(( $t * $ySign )) )) $5 $6
     else
        drawPixel $1 $(( $2 + $(( $t * $ySign )) )) $5 $6
     fi
  done
fi
}

drawByteAsRow(){ #startX startY byte color instant
  for ((i=0;i<8;i++)) do
    if [ $(( $3 & $(( 0x01 << $i )) )) -ne 0 ]; then
      drawPixel $(( $1 + $i )) $2  $4 $5
    fi
  done
}

drawByteAsCol(){ #startX startY byte color instant
  for ((i=0;i<8;i++)) do
    if [ $(( $3 & $(( 0x01 << $i )) )) -ne 0 ]; then
      drawPixel $1 $(( $2 + $i )) $4 $5
    fi
  done
}

drawUpdateByteAsCol(){ #startX startY byte color instant
  for ((i=0;i<8;i++)) do
    if [ $(( $3 & $(( 0x01 << $i )) )) -ne 0 ]; then
      drawPixel $1 $(( $2 + $i )) $4 $5
    else
      drawPixel $1 $(( $2 + $i )) 0 $5
    fi
  done
}

function drawText() { #startX startY string color instant
  local a=0; local b=0; local achar=0; local charp=0; local charout="";
  local text=${3}
  local textlen=${#text}
  for (( a=0; a<${textlen}; a++ )); do
    achar="`ord ${text:${a}:1}`"               # get the ASCII Code
    let charp=(achar-32)*${font_width}         # calculate first byte in font array
    charout=""
    for (( b=0; b<${font_width}; b++ )); do    # character loop
      charout="${charout} ${font[charp+b]}"    # build character out of single values
      drawByteAsCol $(( $1 + $b + $(( $a << 3 )) )) $2 ${font[charp+b]} $4 $5
    done 
  done
}

function drawUpdateText() { #startX startY string color instant
  local a=0; local b=0; local c=0; local achar=0; local charp=0; local charout="";
  local text=${3}
  local textlen=${#text}
  for (( a=0; a<${textlen}; a++ )); do
    achar="`ord ${text:${a}:1}`"               # get the ASCII Code
    let charp=(achar-32)*${font_width}         # calculate first byte in font array
    charout=""
    for (( b=0; b<${font_width}; b++ )); do    # character loop
      charout="${charout} ${font[charp+b]}"    # build character out of single values
      drawUpdateByteAsCol $(( $1 + $b + $(( $a << 3 )) )) $2 ${font[charp+b]} $4 $5
    done 
  done
  local endTextX=$(( $1 + $(( ${textlen} * 8 )) )) #blank out the rest of the line to erase in case of longer previous text
  for (( c=$endTextX; c<129; c++ )); do
    drawUpdateByteAsCol $c $2 0xFF 0x00 $5
  done
}


display_off
init_display
display_on

blankBuffer
loadBuffer

init_temp_sensor_default_config

drawText 1 0 "MiSTer Sys Info" 15 1

old_time_date="$(date +"%H:%M  %m/%d/%y")"

drawText 1 10 "${old_time_date}" 1 1

old_cpu_usage="$(top -n 1 | awk 'FNR==2 {printf "%s",$2}')"

drawText 2 20 "CPU:" 12 1 ; drawText 36 20 "${old_cpu_usage}" 1 1

old_free_ram="$(free -m | awk 'NR==2{printf "%sMB(%.f%%)\n", $2,$3*100/$2 }')"

drawText 2 30 "RAM:" 12 1 ; drawText 36 30 "${old_free_ram}" 1 1

old_free_ssd="$(df -h | awk 'FNR==3 {printf "%dGB(%s)",$2,$5}')"

drawText 2 40 "SSD:" 12 1 ; drawText 36 40 "${old_free_ssd}" 1 1

old_temperature="$(read_temperature)"

drawText 2 50 "TEMP:" 12 1 ; drawText 44 50 "${old_temperature}" 1 1

old_eth_ip="$(/sbin/ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')" 
if [[ -z "$old_eth_ip" ]] ; then
  old_eth_ip="none"
fi

drawText 2 63 "Eth0 IP:" 12 1 ; drawText 0 73 "${old_eth_ip}" 1 1

old_wlan_ip="$(/sbin/ip -4 -o addr show dev wlan0| awk '{split($4,a,"/");print a[1]}')"
if [[ -z "$old_wlan_ip" ]] ; then
  old_wlan_ip="none"
fi

drawText 2 85 "WLan0 IP:" 12 1 ; drawText 0 95 "${old_wlan_ip}" 1 1

old_core_name="$(cat ${corenamefile})" 

drawText 4 110 "CORE:" 8 1 ; drawText 8 120 "${old_core_name}" 1 1


while true; do

time_date="$(date +"%H:%M  %m/%d/%y")"
if [[ "$time_date" != "$old_time_date" ]] ; then
  drawUpdateText 1 10 "${time_date}" 1 1
  old_time_date="${time_date}"
fi

cpu_usage="$(top -n 1 | awk 'FNR==2 {printf "%s",$2}')"
if [[ "$cpu_usage" != "$old_cpu_usage" ]] ; then
# drawRect 60 20 68 30 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 36 20 "${cpu_usage}" 1 1
  old_cpu_usage="${cpu_usage}"
fi

free_ram="$(free -m | awk 'NR==2{printf "%sMB(%.f%%)\n", $2,$3*100/$2 }')"
if [[ "$free_ram" != "$old_free_ram" ]] ; then
# drawRect 60 30 84 40 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 36 30 "${free_ram}" 1 1
  old_free_ram="${free_ram}"
fi

free_ssd="$(df -h | awk 'FNR==3 {printf "%dGB(%s)",$2,$5}')"
if [[ "$free_ssd" != "$old_free_ssd" ]] ; then
# drawRect 36 40 120 50 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 36 40 "${free_ssd}" 1 1
  old_free_ssd="${free_ssd}"
fi

temperature="$(read_temperature)"
if [[ "$temperature" != "$old_temperature" ]] ; then
# drawRect 44 50 120 60 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 44 50 "${temperature}" 1 1
  old_temperature="${temperature}"
fi

eth_ip="$(/sbin/ip -4 -o addr show dev eth0| awk '{split($4,a,"/");print a[1]}')" 
if [[ -z "$eth_ip" ]] ; then
  eth_ip="none"
fi
if [[ "$eth_ip" != "$old_eth_ip" ]] ; then
# drawRect 0 73 128 83 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 0 73 "${eth_ip}" 1 1
  old_eth_ip="${eth_ip}"
fi

wlan_ip="$(/sbin/ip -4 -o addr show dev wlan0| awk '{split($4,a,"/");print a[1]}')"
if [[ -z "$wlan_ip" ]] ; then
  wlan_ip="none"
fi
if [[ "$wlan_ip" != "$old_wlan_ip" ]] ; then
# drawRect 0 95 128 105 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 0 95 "${wlan_ip}" 1 1
  old_wlan_ip="${wlan_ip}"
fi

core_name="$(cat ${corenamefile})" 
if [[ "$core_name" != "$old_core_name" ]] ; then
# drawRect 32 120 128 128 0x00 1     #draw a dark rectagle on the text area to erase previous core name. Icrease size if needed.
  drawUpdateText 8 120 "${core_name}" 1 1  
  old_core_name="${core_name}"
fi

sleep 1

done  






