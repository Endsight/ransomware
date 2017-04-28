@echo off
for /f "tokens=4-6 delims=[. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "6.0" goto install
if not "%version%" == "6.0" goto error


:install
servermanagercmd -install FS-FileServer -logpath "C:\scripts\FS-FileServer.txt"
servermanagercmd -install FS-Resource-Manager -logpath "C:\scripts\FS-Resource-Manager.txt"
servermanagercmd -install RSAT-FSRM-Mgmt -logpath "C:\scripts\RSAT-FSRM-Mgmt.txt"
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" /ve > nul 2>&1
echo.
echo.
if errorlevel 1 (
	echo SUCCESS: All features were installed, check the logs if there were any errors.
) else (
	echo WARNING: A reboot is required to complete installaion of one or more features.
)
goto end


:error
echo.
echo.
echo ERROR: This script is only for Server 2008 first edition (NT 6.0)


:end
