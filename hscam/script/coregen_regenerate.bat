rem C:\Xilinx\ISE_DS\ISE\bin\nt64\coregen.exe -b d:\Work\Linkos\tst\core_gen\cosole\dd_fifo.xco -p d:\Work\Linkos\tst\core_gen\cosole\coregen.cgp -r
rem Regenerate all core

cd D:\Work\Linkos\veresk_m\hscam\ise\src\core_gen
for /R  %%p in (*.cgp) do for /R  %%f in (*.xco ) do C:\Xilinx\ISE_DS\ISE\bin\nt64\coregen.exe -b "%%f" -p "%%p" -r