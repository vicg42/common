rem »щем каталог core_gen и копируем из нее все файлы (*.xco ) в каталог проекта ISE(..\ise\src\core_gen)

cd D:\Work\Linkos\veresk_m\common\hw\
for /R  %%f in ( core_gen\*.xco ) do xcopy "%%f" d:\Work\Linkos\veresk_m\alpha6T1\ise\src\core_gen /y

dir