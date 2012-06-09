 ак сделать проект:

*)  установить и запустить программу клиент SVN (например TortoiseSVN (http://tortoisesvn.net/downloads.html))

*)  выпистать из SVN репозиторий veresk_m (или по не нашему SVN Checkout)
    URL of repository: svn://10.1.7.240:3691/veresk_m
    Checkout directory: путь куда копировать данные репозитори€ (например D:\Work\Linkos\veresk_m)
    login   :guest
    password:linkos

*)  скорректировать пути в следующих файлах:
    veresk_m/xxx/script/firmware_copy.bat
    veresk_m/xxx/make_project.bat
    veresk_m/xxx/updata_ngc.bat

    где xxx - каталог соответствующей платы (alpha5T1,alpha6T1,htg_v6))

    например. make_project.bat - %XILINX%\bin\nt64\xtclsh D:\Work\Linkos\veresk_m\ml505\script\mprj_veresk.tcl

    a)  %XILINX%\bin\nt64\xtclsh - путь к программе xtclsh (дл€ Win-64bit)
        %XILINX%\bin\nt\xtclsh   - путь к программе xtclsh (дл€ Win-32bit)
        (%XILINX% - переменна€ среды в Windows.)
        ƒл€ примера, значени€ переменной среды на моей машине:
        ѕеременна€: XILINX
        «начение  : C:\Xilinx\ISE_DS\ISE

    б)  D:\Work\Linkos\veresk_m\ml505\script\mprj_veresk.tcl -> (какойто новый путь)\veresk_m\ml505\script\mprj_veresk.tcl

*)  перейти к каталогу нужной платы (например veresk_m/alpha6T1)

*)  запустить core generator и перейти к каталогу core_gen соотв. платы (veresk_m/alpha6T1/ise/src/core_gen).
*)  открыть файл проекта core generator
*)  перегенерить все модули

*)  в каталоге ise создать папку prj (veresk_m/alpha6T1/ise/prj)
*)  запустить скрипт создани€ проекта ISE (veresk_m/alpha6T1/script/make_veresk.bat)

*)  запустить скрипт копировани€ файлов core generator в каталог проекта ISE (veresk_m/alpha6T1/script/updata_ngc.bat)

*)  запустить ISE, скомпелировть созданный проект