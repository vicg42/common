Как сделать проект:

*)  установить и запустить программу клиент SVN (например TortoiseSVN (http://tortoisesvn.net/downloads.html))

*)  выпистать из SVN репозиторий veresk_m (или по не нашему SVN Checkout)
    URL of repository: svn://10.1.7.240:3691/veresk_m
    Checkout directory: путь куда копировать данные репозитория (например D:\Work\Linkos\veresk_m)
    username : guest
    password : linkos

*)  скорректировать пути в следующих файлах:
    veresk_m/xxx/script/firmware_copy.bat
    veresk_m/xxx/make_project.bat
    veresk_m/xxx/updata_ngc.bat

    где xxx - каталог проекта VERESK для соответствующей платы (alpha5T1,alpha6T1,htg_v6))

    например. make_project.bat - %XILINX%\bin\nt64\xtclsh D:\Work\Linkos\veresk_m\ml505\script\mprj_veresk.tcl

    a)  %XILINX%\bin\nt64\xtclsh - путь к программе xtclsh (для Win-64bit)
        %XILINX%\bin\nt\xtclsh   - путь к программе xtclsh (для Win-32bit)
        (%XILINX% - переменная среды в Windows.)
        Для примера, значения переменной среды на моей машине:
        Переменная: XILINX
        Значение  : C:\Xilinx\ISE_DS\ISE

    б)  D:\Work\Linkos\veresk_m\ml505\script\mprj_veresk.tcl -> (какойто новый путь)\veresk_m\ml505\script\mprj_veresk.tcl

*)  перейти к каталогу нужной платы (например veresk_m/alpha6T1)

*)  запустить программу от Xilinx Core Generator и перейти к каталогу core_gen соотв. платы (veresk_m/alpha6T1/ise/src/core_gen).
*)  открыть файл проекта core generator
*)  перегенерить все модули (в меню Core Generator выбрать Project/Regenerate all project IP(under curent project settings)

*)  запустить скрипт создания проекта ISE (veresk_m/alpha6T1/script/make_veresk.bat)

*)  запустить скрипт копирования файлов core generator в каталог проекта ISE (veresk_m/alpha6T1/script/updata_ngc.bat)

*)  запустить ISE, скомпелировть созданный проект

*)  запустить скрипт firmware_copy.bat (например для платы AD6T1 - veresk_m/alpha6T1/script/firmware_copy.bat)


прошивка платы HTGV6:
*)  подсоеденить JTAG к разъему J35
*)  запустить скрипт veresk_m/htg_v6/script/prom_download.bat