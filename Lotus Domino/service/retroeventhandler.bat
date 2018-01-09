@echo off
REM
REM Retrospect Event Handler - Lotus Domino Server
REM 
REM          This batch file will stop a Lotus Domino server running as a 
REM service when a Retrospect script named "Backup Domino" is run. It will 
REM restart the server after the script is finished.
REM	
REM	The service defined in this script must match the service name in
REM the services control panel.
REM
REM (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.n
REM

REM The following code branches to the procedure labels below, it should not be
REM modified.
If NOT {%1}=={} goto :ENDMSG
	echo     This batch file will stop a Lotus Domino server running as a 
	echo service when a Retrospect script named "Backup Domino" is run. 
	echo It will restart the Domino Server after the script is finished.
	echo      To use this file, copy it to the Retrospect directory.
	pause
	goto :RETURN_OK
:ENDMSG

if {%1}=={} goto :RETURN_OK
set _PROC=%1
shift
goto :%_PROC%


REM -- Begin StartSource------------------------------------------------------
:StartSource
set scriptName=%1

REM scriptName can be edited to match script names in Retrospect.
if {%scriptName%}=={"Backup Domino"} call :STOP_DOMINO_SERVER

goto :RETURN_OK REM -- End StartSource
REM ---------------------------------------------------------------------------


REM -- Begin EndSource --------------------------------------------------------
:EndSource 
set scriptName=%1

if {%scriptName%}=={"Backup Domino"} call :START_DOMINO_SERVER

goto :RETURN_OK REM -- End EndSource 
REM ---------------------------------------------------------------------------


REM Stop the Domino Server by stopping the service.
REM Domino Server must be running as a service.
:STOP_DOMINO_SERVER

REM Stop the Domino Server.
echo Stopping Domino Server

REM Service name must exactly match the service you are stopping.
net stop "Lotus Domino Server"

goto :RETURN_OK

REM Start the Domino server 
:START_DOMINO_SERVER

echo Starting Domino Server

REM Service name must exactly match the service you are starting.
net start "Lotus Domino Server"


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

