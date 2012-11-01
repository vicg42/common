--#######################
--ML505 - общее
--#######################

1. Тип загрузки FPGA:
-------------------------------------------------
DIP switch(SW3): | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
-------------------------------------------------
JTAG             | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 0 |
PROM             | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |


2. SATA
DUAL_GTP: GTP_X0Y2

J40 - SATA-HOST1 - от PCI-express разъем -2 (DUAL_GTP:CH0)
J41 - SATA-HOST2 - от PCI-express разъем -1 (DUAL_GTP:CH1)


3. Светодиды:

Расположение:

PCI-Express     L L L L          L L L L
                E E E E          E E E E
                D D D D          D D D D
                0 1 2 3          4 5 6 7


4. Обновление значений BRAM с помощью утилиты data2mem
(более подробно о использовании утилиты data2mem см. d:\Help\Doc_Hardware\Xilinx\Xilinx_Doc\data2mem_standalone.pdf + data2mem_ug658.pdf)

scripts/eth_prm_xdl.bat    -- после создания файла *.xdl в нем нужно найти куда именно XST определил ETH_BRAM_PRM (LOC)
scripts/eth_prm_update.bat -- обновляет значения ETH_BRAM_PRM
scripts/eth_prm_dump.bat   -- можно проверить (через поиск) правильно ли обновились значения ETH_BRAM_PRM


