rem »щем каталог core_gen и копируем из нее все файлы (*.ngc,*.mif ) в каталог проекта ISE(..\ise\prj)

cd D:\Work\Linkos\veresk_m\alpha5T1\ise\src\core_gen\
for /R  %%f in ( *.ngc  *.mif) do xcopy "%%f" ..\..\prj /y

dir