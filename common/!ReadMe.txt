Как создать проект для ISE

* установить и запустить программу клиент SVN (например TortoiseSVN (http://tortoisesvn.net/downloads.html))

* выпистать из SVN репозиторий veresk_m (или по не нашему SVN Checkout)
  URL of repository: svn://10.1.7.240:3691/veresk_m
  Checkout directory: путь куда копировать данные репозитория (например D:\Work\Linkos\veresk_m)
  username : guest
  password : linkos

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

