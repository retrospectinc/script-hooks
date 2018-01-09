@echo off
REM
REM Sample Retrospect Event Handler
REM 
REM     This batch file will pause Microsoft's Exchange server when a Retrospect
REM script named "Backup Exchange" is run. It will restart the server after the
REM script is finished.
REM
REM (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
REM 


REM The following code branches to the procedure labels below, it should not be
REM modified.
If NOT {%1}=={} goto :ENDMSG
	echo     This batch file will pause Microsoft's Exchange server when a Retrospect
	echo script named "Backup Exchange" is run. It will restart the server after the
	echo script is finished.
	Echo      To use this file, copy it to the Retrospect directory.
	pause
	goto :RETURN_OK
:ENDMSG
set _PROC=%1
shift
goto :%_PROC%


REM -- Begin StartSource------------------------------------------------------
:StartSource
set scriptName=%1

if {%scriptName%}=={"Backup Exchange"} call :PAUSE_EXCHANGE_SERVER %serverName%

goto :RETURN_OK REM -- End StartSource
REM ---------------------------------------------------------------------------


REM -- Begin EndSource --------------------------------------------------------
:EndSource 
set scriptName=%1

if {%scriptName%}=={"Backup Exchange"} call :CONTINUE_EXCHANGE_SERVER %serverName%

goto :RETURN_OK REM -- End EndSource 
REM ---------------------------------------------------------------------------


REM Pause the exchange server by calling the external "controlService" to pause
REM all of Exchange's services.
:PAUSE_EXCHANGE_SERVER

REM Stop all services
echo Stopping Services...
net stop MSExchangeMSMI
net stop MSExchangePCMTA
net stop MSExchangeFB
net stop MSExchangeDX
net stop MSExchangeIMC
net stop MSExchangeMTA
net stop MSExchangeES
net stop MSExchangeIS
net stop MSExchangeDS
net stop MSExchangeSA
goto :RETURN_OK

REM Restart the exchange server by calling the external "controlService" to 
REM continue all of Exchange's services.
:CONTINUE_EXCHANGE_SERVER

REM edbutil OPTIONS
echo Restarting Services...
net start MSExchangeSA
net start MSExchangeDS
net start MSExchangeIS
net start MSExchangeES
net start MSExchangeMTA
net start MSExchangeIMC
net start MSExchangeDX
net start MSExchangeFB
net start MSExchangePCMTA
net start MSExchangeMSMI

goto :RETURN_OK


REM stub procedure tags
:StartApp
:EndApp
:StartBackupServer
:StopBackupServer
:StartScript
:StopScript
:MediaRequest
:TimedOutMediaRequest
:ScriptCheckFailed
:NextExec
:StopSched
:PasswordEntry

:RETURN_OK
