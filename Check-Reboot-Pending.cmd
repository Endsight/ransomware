@echo off
echo.
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" /ve > nul 2>&1
if errorlevel 1 (
	echo SUCCESS: There is no reboot pending
) else (
	echo WARNING: Server is pending a reboot
)
echo.
pause
