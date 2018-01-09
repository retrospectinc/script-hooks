@echo off
REM
REM Sample Retrospect Event Handler
REM 
REM     The Retrospect application will call this batch file with the first
REM argument as the subroutine name (e.g. "EndSource").
REM     Procedures supported by Retrospect 5.1:
REM StartApp -- Retrospect has been launched
REM EndApp -- Retrospect is quitting
REM StartBackupServer - The backup server is starting
REM StopBackupServer - The backup server is stopping
REM StartScript - A script is beginning
REM EndScript - A script is stopping
REM StartSource - A volume is about to be backed up
REM EndSource - A volume has been backed up
REM 
REM MediaRequest - Retrospect needs media and has put up a dialog requesting it.
REM TimedOutMediaRequest - If "Media Request Times Out" is set in "Special-Preferences"
REM     then this message is sent before timing out. Return an error to cause
REM     Retrospect to reset its timer.
REM 
REM ScriptCheckFailed - Called before Retrospect quits if the next scheduled
REM     script will not be able to run (due to no media or other conditions).
REM NextExec - Called before Retrospect quits with the name and start date of
REM     the next script that will be able to run.
REM 
REM StopSched - Called when a script has a scheduled interval to run before the
REM     interval has elapsed. Return an error to cause Retrospect to continue
REM     executing the script.
REM
REM PasswordEntry - Called whenever a password is entered.
REM FatalBackupError - Called whenever an un-recoverable error occurs. (i.e hardware 
REM 	failure)
REM
REM (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
REM 

REM Sample Call:
REM retroEventHandler StartApp "1/1/2000 12:01 AM" "true"


REM The following code can be used to examine the arguments passed with an event.
REM Comment the following line to enable this feature:
goto :EndEchoArgs
set /a numArgs=0
echo Event message is: %1
:EchoArgs
shift
set /a numArgs = numArgs + 1
if {%1}=={} goto :EndLoopEchoArgs
echo Argument '%numArgs%' = %1
goto :EchoArgs
:EndLoopEchoArgs
pause
:EndEchoArgs
REM ---------------------------------------------------------------------------


REM The following code branches to the procedure labels below, it should not be
REM modified.

If NOT {%1}=={} goto :ENDMSG
	Echo      This is a sample Retrospect external script written in the
	Echo Windows batch command language. It will display a message for each
	Echo Retrospect event.
	Echo     To use this file on the backup server, move it to Retrospect's directory
	Echo To use this file on a client machine, copy it to the directory containing
	Echo the Retrospect client ('retroclient.exe').
	pause
	goto :EXIT
:ENDMSG
set _PROC=%1
shift
goto :%_PROC%


REM -- Begin StartApp ---------------------------------------------------------
:StartApp
set startDate=%1
set autoLaunched=%2
set interventionFile=%3

REM -- Replace the following lines with your StartApp procedure
if  NOT %autoLaunched%=="true" goto :else_StartApp
	echo Retrospect is autolaunching on %startDate%
	goto :end_StartApp
:else_StartApp
	echo Retrospect is launching on %startDate%
:end_StartApp

ask /T:Y,60 Let Retrospect start?
if not errorlevel 2 goto :endif_Continue_StartApp
	echo Retrospect will quit now.
	pause
	echo Retrospect launch stopped by external script. > %interventionFile%
:endif_Continue_StartApp

goto :EXIT REM -- End StartApp
REM ---------------------------------------------------------------------------


REM -- Begin EndApp -----------------------------------------------------------
:EndApp
set endDate=%1

REM -- Replace the following lines with your EndApp procedure
echo Retrospect quit on %endDate%
pause

goto :EXIT REM -- End EndApp
REM ---------------------------------------------------------------------------


REM -- Begin StartBackupServer ------------------------------------------------------
:StartBackupServer
set startDate=%1
set interventionFile=%2

REM -- Replace the following lines with your StartBackupServer procedure
echo Backup Server is starting on %startDate%

ask /T:Y,60 Let Backup Server continue?
if not errorlevel 2 goto :endif_Continue_StartBackupServer
	echo Backup Server will not launch.
	pause
	echo Backup Server launch stopped by external script. > %interventionFile%
:endif_Continue_StartBackupServer

goto :EXIT REM -- End StartBackupServer
REM ---------------------------------------------------------------------------


REM -- Begin StopBackupServer --------------------------------------------------------
:StopBackupServer
set endDate=%1

REM -- Replace the following lines with your StopBackupServer procedure
echo Backup server stopped on %endDate%
pause

goto :EXIT REM -- End StopBackupServer
REM ---------------------------------------------------------------------------


REM -- Begin StartScript ------------------------------------------------------
:StartScript
set scriptName=%1
set startDate=%2
set interventionFile=%3

REM -- Replace the following lines with your StartScript procedure
echo Retrospect script %scriptName% is starting on %startDate%

ask /T:Y,60 Let script continue?
if not errorlevel 2 goto :endif_Continue_StartScript
	echo Script %scriptName% will not execute.
	pause
	echo Script stopped by external script. >  %interventionFile%
:endif_Continue_StartScript

goto :EXIT REM -- End StartScript
REM ---------------------------------------------------------------------------


REM -- Begin EndScript --------------------------------------------------------
:EndScript
set scriptName=%1
set numErrors=%2
set fatalErrCode=%3
set fatalErrMsg=%4

REM -- Replace the following lines with your EndScript procedure
if %fatalErrCode%=="0" goto :else_NonFatalEndScript
	echo Retrospect script %scriptName% stopped by error code #%fatalErrCode% - %fatalErrMsg%
	pause
	goto :endif_EndScript
:else_NonFatalEndScript
	if %fatalErrCode%=="0" goto :else_NoErrorsEndScript
	echo Retrospect script %scriptName% finished with %numErrors% non-fatal errors.
	pause
	goto :endif_EndScript
:else_NoErrorsEndScript
	echo Retrospect script %scriptName% finished with no errors
	pause
:endif_EndScript

goto :EXIT REM -- End EndScript
REM ---------------------------------------------------------------------------


REM -- Begin StartSource ------------------------------------------------------
:StartSource
set scriptName=%1
set volName=%2
set sourcePath=%3 
set clientName=%4 
set interventionFile=%5

REM -- Replace the following lines with your StartSource procedure
echo Retrospect script %scriptName% will back up volume %volName% at %sourcePath% on %clientName%

ask /T:Y,60 Let source start?
if not errorlevel 2 goto :endif_Continue_StartSource
	echo Script %scriptName% will not back up volume %volName%
	pause
	echo Source skipped by external script. > %interventionFile%
:endif_Continue_StartSource

goto :EXIT REM -- End StartSource
REM ---------------------------------------------------------------------------


REM -- Begin EndSource --------------------------------------------------------
:EndSource
set scriptName=%1
shift
set sourceName=%1
shift
set sourcePath=%1
shift
set clientName=%1
shift
set kbBackedUp=%1
shift
set numFiles=%1
shift
set duration=%1
shift
set sourceStart=%1
shift
set sourceEnd=%1
shift
set scriptStart=%1
shift
set backupSet=%1
shift
set backupAction=%1
shift
set parentVol=%1
shift
set numErrs=%1
shift
set fatalErrCode=%1
shift
set fatalErrMsg=%1



REM -- Replace the following lines with your EndSource procedure

if not %fatalErrCode%=="0" goto :Fatal_EndSource
	if not %numErrs%=="0" goto :Error_endSource
	echo Retrospect volume %clientName% located at %sourcepath% on %sourceName% completed successfully.
	goto :end_EdSrce
:Fatal_EndSource
	echo Script %scriptName% was stopped when backing up volume %sourceName% from %clientName% on %sourceEnd%.
	echo Error #%fatalErrCode% - %fatalErrMsg%.
	goto :end_EdSrce
:Error_endSource
	if %numErrs%=="1" goto :one_error
	echo Script %scriptName% finished backing up %clientName%'s volume, %sourceName% with %numErrs% non-fatal errors.
	goto :end_EdSrce
:one_error
	echo Script %scriptName% finished backing up %clientName%'s volume, %sourceName% with %numErrs% error.
	
:end_EdSrce

echo Script %scriptName% did a %backupAction% backup to %backupSet%. 
echo %numFiles% files (%kbBackedUp%KB) were transferred in %duration% seconds. 
echo The script started on %scriptStart%, the volume started on %sourceStart% and finished at %sourceEnd%.
pause


goto :EXIT REM -- End EndSource
REM ---------------------------------------------------------------------------


REM -- Begin MediaRequest -----------------------------------------------------
:MediaRequest
set mediaLabel=%1
set mediaName=%2
set mediaIsKnown=%3
set waited=%4
set interventionFile=%5

REM -- Replace the following lines with your MediaRequest procedure
echo Retrospect is requesting media %mediaName% - %mediaLabel%.
if not {%mediaIsKnown%}=={"true"} goto :else_MediaRequest
	echo Retrospect has backed up to this media before.
goto :end_MediaRequest
:else_MediaRequest
	echo This is either a new or unknown media.
:end_MediaRequest

echo Retrospect has waited %waited% minutes so far.

ask /T:Y,60 Continue with media request?
if not errorlevel 2 goto :endif_Continue_MediaRequest
	echo Media %mediaName% will be skipped.
	pause
	echo Media request aborted by external script. > %interventionFile%
:endif_Continue_MediaRequest


goto :EXIT REM -- End MediaRequest
REM ---------------------------------------------------------------------------


REM -- Begin TimedOutMediaRequest ---------------------------------------------
:TimedOutMediaRequest
set mediaLabel=%1
set mediaName=%2
set mediaIsKnown=%3
set waited=%4
set interventionFile=%5

REM -- Replace the following lines with your TimedOutMediaRequest procedure
echo Retrospect's media request for %mediaName% - %mediaLabel% is about to timed out after waiting %waited% minutes.
ask /T:N,60 Let Retrospect time out?
if not errorlevel 2 goto :else_TimedOutMediaRequest
	echo Resetting timer for media request.
	echo Timer reset by external script. > %interventionFile%	
	pause
	goto :endif_TimedOutMediaRequest
:else_TimedOutMediaRequest
	echo Media request timed out.
	pause
	goto :endif_TimedOutMediaRequest
	
:endif_TimedOutMediaRequest

goto :EXIT REM -- End TimedOutMediaRequest
REM ---------------------------------------------------------------------------



REM -- Begin ScriptCheckFailed ------------------------------------------------
:ScriptCheckFailed
set scriptName=%1
set startDate=%2
set reason=%3
set errCode=%4
set errMsg=%5

REM -- Replace the following lines with your ScriptCheckFailed procedure

echo Script %scriptName% scheduled to run on %startDate% will not execute due to error #%errCode% - %errMsg%
echo Retrospect's dialog: %reason%
pause

goto :EXIT REM -- End ScriptCheckFailed
REM ---------------------------------------------------------------------------


REM -- Begin NextExec ---------------------------------------------------------
:NextExec
set scriptName=%1
set startDate=%2

REM -- Replace the following lines with your NextScriptExec procedure
echo Script %scriptName% is scheduled to run next on %startDate%
pause

goto :EXIT REM -- End NextExec
REM ---------------------------------------------------------------------------


REM -- Begin StopSched --------------------------------------------------------
:StopSched
set scriptName=%1
set stopDate=%2
set interventionFile=%3

REM -- Replace the following lines with your StopSched procedure
echo Script %scriptName% is scheduled to stop its scheduled execution on %stopDate%
ask  /T:N,60 Let the script stop?
If not errorlevel 2 goto :else_StopSched
	echo Script %scriptName% will continue to run
	echo Script %scriptName% will continue to run %stopDate% > %interventionFile%
	pause
	goto :end_StopSched
:else_StopSched
	echo Script %scriptName% will stop on %stopDate%
	pause
:end_StopSched

goto :EXIT REM -- End StopSched
REM ---------------------------------------------------------------------------


REM -- Begin PasswordEntry ----------------------------------------------------
:PasswordEntry
set actionString=%1
set attempts=%2
set errCode=%3
set errMsg=%4

REM -- Replace the following lines with your PasswordEntry procedure

if %errMsg%=="successful" goto :else_PasswordEntry
	echo Login failed after %attempts% attempts (error # %errCode% - %errMsg%)
	echo Retrospect's dialog: %actionString% 
	pause
	goto :end_PasswordEntry
:else_PasswordEntry
	if %attempts%=="1" goto :one_try_PasswordEntry
	echo Login successful after %attempts% attempts.
	echo Retrospect's dialog: %actionString%
	pause
	goto :end_PasswordEntry
:one_try_PasswordEntry
	echo Login successful.
	echo Retrospect's dialog: %actionString%
	pause
	goto :end_PasswordEntry
:end_PasswordEntry


goto :EXIT REM -- End PasswordEntry
REM ---------------------------------------------------------------------------


REM -- Begin FatalBackupError -------------------------------------------------
:FatalBackupError
set scriptName=%1
set failureCause=%2
set errCode=%3
set errMsg=%4
set errZone=%5

REM errMsg contains the text Retrospect puts up in it's dialog.
REM return characters have been replaced with tabs.
REM this may make for odd display.

echo ScriptName %scriptName% failed in %errZone% with error #%errCode% - %errMsg%
echo Retrospect's dialog: %failureCause%
ask  /T:N,60 Do you want to display a modal dialog?
If not errorlevel 2 goto :end_FatalBackupError
	echo External script prevented the display of a modal dialog. > %interventionFile
:end_FatalBackupError


goto :EXIT REM -- End FatalBackupError
REM ----------------------------------------------------------------------------

:EXIT
