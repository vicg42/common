setMode -pff
setSubmode -pffserial
addPromDevice -p 1 -name xcf32p
addDesign -version 0 -name 0
addDeviceChain -index 0
addDevice -p 1 -file D:\Work\Linkos\veresk_m\ml505\firmware\pupok_flash_program_ml505.bit
generate -format mcs -fillvalue FF -output D:\Work\Linkos\veresk_m\ml505\firmware\pupok_flash_program_ml505.mcs
setMode -bs
setCable -port auto
identify
assignFile -p 1 -file D:\Work\Linkos\veresk_m\ml505\firmware\pupok_flash_program_ml505.mcs
setAttribute -position 1 -attr readnextdevice -value "(null)"
Program -p 1 -e -parallel
quit
