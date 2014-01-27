--######################################
--Как создать проект для ISE
--######################################

* установить и запустить программу клиент GIT (TortoiseGIT)

* выпистать из github репозиторий veresk_m
  git clone https://github.com/vicg42/veresk_m

* подключить внешнюю библиотеку:
  - git remote add lib https://github.com/vicg42/common.git
  - git fetch lib
  - git checkout -b common-lib lib/master
  - git checkout master
  - git read-tree --prefix=common/lib -u common-lib
  - git commit
  - git merge -s subtree common-lib

* теперь все слияния с веткой common-lib нужно делать используя флаг -s subtree!!!!

* скорректировать пути в следующих файлах:
  veresk_m/xxx/script/firmware_copy.bat - копирование файла прошивки в отдельный каталог
  veresk_m/xxx/script/make_project.bat - создание проекта для ISE
  veresk_m/xxx/script/updata_ngc.bat - копирование *.ngc файлов в каталог проекта ISE

  например: make_project.bat - %XILINX%\bin\nt64\xtclsh (какойто новый путь)\veresk_m\xxx\script\mprj_veresk.tcl

  где xxx - каталог проекта для соответствующей платы:
  alpha5T1 - плата AlphaData 5T1
  alpha6T1 - плата AlphaData 6T1
  htg_v6   - плата HTG
  hscam    - проект скоросного канала для Вереск-Р

  %XILINX%\bin\nt64\xtclsh - путь к программе xtclsh (для Win-64bit)
  %XILINX%\bin\nt\xtclsh   - путь к программе xtclsh (для Win-32bit)
  (%XILINX% - переменная среды в Windows.)
  Для примера. Значения переменной среды на моей машине:
  Переменная: XILINX
  Значение  : C:\Xilinx\ISE_DS\ISE

* перейти к каталогу нужной платы (например .../veresk_m/alpha6T1)

* запустить программу от Xilinx Core Generator и перейти к каталогу core_gen соотв. платы (.../veresk_m/alpha6T1/ise/src/core_gen).
* открыть файл проекта core generator
* перегенерить все модули (в меню Core Generator выбрать Project/Regenerate all project IP(under curent project settings)

* запустить скрипт создания проекта ISE (.../veresk_m/alpha6T1/script/make_veresk.bat)
  !!! если необходимо пересоздать проект ISE, то перед запуском скрипта make_veresk.bat
  необходимо удалить из каталога .../ise/prj файлы *.xise и закрыть (Project close) открытые проекты в программе Xilinx ISE

* запустить скрипт копирования файлов core generator в каталог проекта ISE (.../veresk_m/alpha6T1/script/updata_ngc.bat)

* запустить ISE, скомпелировть созданный проект

* запустить скрипт firmware_copy.bat (например для платы AD6T1 - .../veresk_m/alpha6T1/script/firmware_copy.bat)


прошивка платы HTGV6:
* подсоеденить JTAG к разъему J35
* запустить скрипт .../veresk_m/htg_v6/script/prom_download.bat



--#######################################
--каталоги
--#######################################
* veresk_m/common  - общие файлы для всех плат
  veresk_m/common/prj_def.vhd  - константы регистров
  veresk_m/common/lib  - библиотела модулей HDL

* veresk_m/xxx - xxx - каталог проекта для соответствующей платы:

  1. .../cscope - все что относится в ChipScope.
                  *.tok - имена состояний автоматов управления

  2. .../firmware - прошивки

  3. .../ise/prj - проект ISE
     .../ise/src - исходники проекта
     .../ise/src/*prj_cfg.vhd - настройка проекта для соответствующей платы
     .../ise/src/core_gen - каталог для ядер CoreGenerator

  4. .../sim/mscript -- скрипты для ModelSim
     .../sim/testbanch -

  5. .../script - скрипты проекта
               - updata_ngc.bat - обновление файлов core_gen в каталоге проекта ISE (ise/prj)
               - jtag_download.bat /jtag_download.cmd - загрузка проекта через JTAG
               - prom_download.bat /prom_download.cmd - загрузка проекта в PROM
               - make_project.bat - сборка проекта для Xilinx ISE
               - mprj_xxx.tcl - сборка проекта для Xilinx ISE (где xxx - имя вернего уровня)

  6. .../ucf


--#######################################
--
--#######################################
ERROR: sensitivity list

Logs ISE:
*.syr - log XST
*.bld - log Translate
*.mrp - Map report
*.par - Place and Route report


--#######################################
--LINUX
--#######################################
если работать с Xilinx под Linux, то в скриптах сознания проектов нужно сделать следующие изменения:
1 make_project.bat - xtclsh ./mpj_xxx.tcl
2.сделать этот файл выполняемым. (chmod +x ...)

--#######################################
--Chip Scope
--#######################################
Как смотреть времянки на удаленной FPGA:
1. К FPGA подсоеденить JTAG от удаленной PC.
2. На удаленной PC запустить server. (Xilinx/ISE_DS/bin/nt(или nt64) cse_sever -port 50001
3. На своей PC запускаем Chipscope. Переходим к закладке JTAG Chain/Server Host Setting
4. Изменяем настройки: IP компьютера с JTAG:50001
5. Все!!! Теперь можно смотрим времяенки )))

--#######################################
--Git
--#######################################
merge веток devel <-> common-lib ТОЛЬКО C ФЛАГОМ -s subtree!!!