setMode -pff
setSubmode -pffbpi
setAttribute -configdevice -attr multibootBpiType -value "TYPE_BPI"
setAttribute -configdevice -attr multibootBpiDevice -value "VIRTEX6"
setAttribute -configdevice -attr multibootBpichainType -value "PARALLEL"
addDesign -version 0 -name "0"
addDeviceChain -index 0
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr autoSize -value "FALSE"
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr swapBit -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "FALSE"
setAttribute -configdevice -attr ironhorsename -value "1"
setAttribute -configdevice -attr flashDataWidth -value "16"
setCurrentDesign -version 0
addPromDevice -p 1 -size 32768 -name 32M
setAttribute -design -attr RSPin -value "00"
addDevice -p 1 -file "D:\Work\Linkos\veresk_m\ml505\firmware\veresk_main.bit"
generate -format mcs -fillvalue FF -output D:\Work\Linkos\veresk_m\ml505\firmware\veresk_main.mcs
setMode -bs
setCable -port auto
identify
attachflash -position 5 -bpi "28F256P30"
assignfiletoattachedflash -position 5 -file "D:\Work\Linkos\veresk_m\ml505\firmware\veresk_main.mcs"
program -p 5 -dataWidth 16 -rs1 NONE -rs0 NONE -bpionly -e -v -loadfpga
quit
