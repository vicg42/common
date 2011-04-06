rem »щем каталог core_gen и копируем из нее все файлы (*.ngc,*.mif ) в каталог проекта ISE(..\ise\prj)

cd D:\Work\Linkos\veresk_m\common\hw
for /R  %%f in (core_gen\*.ngc core_gen\*.mif) do xcopy "%%f" ..\..\alpha5T1\ise\prj /y

cd D:\Work\Linkos\veresk_m\common\veresk_m
for /R  %%f in (core_gen\*.ngc core_gen\*.mif) do xcopy "%%f" ..\..\alpha5T1\ise\prj /y

cd D:\Work\Linkos\veresk_m\alpha5T1\ise\src
for /R  %%f in (core_gen\*.ngc core_gen\*.mif) do xcopy "%%f" ..\prj /y

dir