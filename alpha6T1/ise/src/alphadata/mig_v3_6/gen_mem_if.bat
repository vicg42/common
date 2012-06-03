@echo off
::
:: Script for use with ISE12.3 MIG v3.6 onwards
::
@set _MIG_Temp=.\mig_temp
@set _MIG_Version=mig_v3_6
::
@set _XCO_Path=.\xco\%1.xco
@set _XCO_Dest=%1.xco
::
@set _CGP_Path=.\cgp\%1.cgp
@set _CGP_Dest=%1.cgp
::
@set _CUS_Path=.\prj\custom_part
@set _CUS_Dest=custom_part
::
@set _PRJ_Path=.\prj\banks4_1Gb_187e_%1.prj
@set _PRJ_Dest=%_MIG_Version%\user_design\mig.prj
::
@if not exist %_XCO_Path%  goto switch_error
@if not exist %_CGP_Path%  goto switch_error
@if not exist %_CUS_Path%  goto switch_error
@if not exist %_PRJ_Path%  goto switch_error
::
@echo.
@echo Device Selected: %1
@echo.
::@echo Project File: %_CGP_Path%
::@echo MIG Parameters: %_XCO_Path%
::@echo MIG Parameters: %_PRJ_Path%
::@echo MIG Parameters: %_CUS_Path%
::@echo.
::
::
@echo.
@echo Creating %_MIG_Temp% temporary directory
@echo.
@if exist %_MIG_Temp% rmdir /q/s %_MIG_Temp%
@mkdir %_MIG_Temp%
@mkdir %_MIG_Temp%\%_MIG_Version%
@mkdir %_MIG_Temp%\%_MIG_Version%\user_design
::
@echo.
@echo Copying files:
@echo.
@echo Copying CGP file %_CGP_Path% to %_CGP_Dest%
@copy %_CGP_Path% %_MIG_Temp%\%_CGP_Dest%
@echo Copying PRJ file %_PRJ_Path% to %_PRJ_Dest%
@copy %_PRJ_Path% %_MIG_Temp%\%_PRJ_Dest%
@echo Copying XCO file %_XCO_Path% to %_XCO_Dest%
@copy %_XCO_Path% %_MIG_Temp%\%_XCO_Dest%
@echo Copying custom parts %_CUS_Path% to %_CUS_Dest%
@xcopy  /E %_CUS_Path% %_MIG_Temp%\%_CUS_Dest% /I /Y
::
@echo.
@echo Generating MIG files:
@echo.
@cd %_MIG_Temp%
@echo C:\Xilinx\ISE_DS\ISE\bin\nt64\coregen.exe -r -b %_XCO_Dest%  -p %_CGP_Dest%
@C:\Xilinx\ISE_DS\ISE\bin\nt64\coregen.exe -r -b %_XCO_Dest%  -p %_CGP_Dest%
@if errorlevel 1 goto coregen_error
::
::
@echo.
@echo Copying generated VHDL to rtl folder
@cd ..
@copy %_MIG_Temp%\coregen.log .
@if exist .\rtl rmdir /q/s .\rtl
@mkdir rtl
@xcopy %_MIG_Temp%\%_MIG_Version%\user_design\rtl .\rtl /S /I /Y
@if errorlevel 1 goto copy_error
::rmdir %_MIG_Temp% /S /Q
::
::
@echo.
@echo Generation of MIG cores complete.
@echo.
@exit /b 0
::
::
:copy_error
@echo.
@echo RTL copy error
@echo Source: %_MIG_Temp%\%_MIG_Version%\user_design\rtl
@echo Dest  : .\rtl
@echo.
@exit /b %errorlevel%

:switch_error
@echo.
@echo Batch file input error: %1
@echo.
@echo Please enter a valid device type: 6vlx240t/6vlx365t/6vlx550t/6vsx315t/6vsx475t
@echo For example:
@echo.
@echo gen_mem_if.bat 6vlx240t
@echo.
@exit /b -1
::
::
:coregen_error
@echo.
@echo CORE Generator error detected
@echo.
@exit /b %errorlevel%
