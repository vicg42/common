Как сделать проект:

0.  Выпистать из SVN репозиторий veresk_m

1.  Скорректировать пути в следующих файлах:
    veresk_m/xxx/script/firmware_copy.bat
    veresk_m/xxx/make_project.bat
    veresk_m/xxx/updata_ngc.bat

    (%XILINX% - переменная среды в Windows.)
    Для примера, значения переменной среды на моей машине:
    Переменная: XILINX
    Значение  : C:\Xilinx\ISE_DS\ISE

2.  перейти к каталогу нужной платы (например veresk_m/alpha6T1)

3   запустить core generator и перейти к каталогу core_gen соотв. платы (veresk_m/alpha6T1/ise/src/core_gen).
    открыть файл проекта core_gen.
3.1 перегенерить все модули core_gen.

4.  В каталоге ise создать папку prj (veresk_m/alpha6T1/ise/prj)
4.1 запустить скрипт создания проекта ISE (veresk_m/alpha6T1/script/make_veresk.bat)

5.  запустить скрипт копирования файлов core_gen в каталог проекта ISE (veresk_m/alpha6T1/script/updata_ngc.bat)

6.  Запустить ISE, скомпрелировть созданный проект