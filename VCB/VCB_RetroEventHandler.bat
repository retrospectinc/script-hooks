@echo off

REM ---------------------------------------------------------------------------
REM                VCB_RetrospectEventHandler - VCB backups
REM ---------------------------------------------------------------------------


REM ---------------------------------------------------------------------------
REM                         ABOUT THIS SCRIPT
REM ---------------------------------------------------------------------------
REM     Retrospect can use this batch file to call the pre-command.wsf VCB script
REM to mount a VM image at start of a backup of a VM source, and then at end of the
REM backup call vcbCleanup.bat to clean up the mount point. The type of mount (image
REM or file) is determined by the volumeName such that if the volume name ends with
REM "-fullVM" then it will be an image backup. Any other volume name will be a file
REM level mount. The volume name should be the name of the VM as the ESX server sees
REM them. To see VM names that an ESX server controls, run the vcbVmName executable
REM (ex: "c:\vcb_framework\vcbVmName.exe" -h esxserver.vmware.com  -u vcbUser -p
REM vcbpasswd -sAny -L 0)


REM ---------------------------------------------------------------------------
REM                             INSTRUCTIONS
REM ---------------------------------------------------------------------------
REM THE VCB_FRAMEWORK_PATH variable below must be set before running this batch
REM file (ex: set VCB_FRAMEWORK_PATH=C:\YOUR_VCB_FRAMEWORK)
REM 
REM The config.js settings file located on the VCB proxy server
REM (path: C:\YOUR_VCB_FRAMEWORK\config\config.js) must have the following
REM variables listed below set to specifically match your VCB setup:
REM
REM BACKUPROOT=<path_to_mount>;         (ex: BACKUPROOT="C:\\vcb_mnts";)
REM HOST=<esxserver_hostname>;          (ex: HOST="esxserver.vmware.com";)
REM USERNAME=<user name>;               (ex: USERNAME="vcbUser";)
REM PASSWORD=<password>;                (ex: PASSWORD="vcbpasswd";)
REM VM_LOOKUP_METHOD="name";            (ex: VM_LOOKUP_METHOD="name";)
REM PREEXISTING_MOUNTPOINT="delete";    (ex: PREEXISTING_MOUNTPOINT="delete";)
REM PREEXISTING_VCB_SNAPSHOT="delete";  (ex: PREEXISTING_VCB_SNAPSHOT="delete";)


REM ---------------------------------------------------------------------------
REM                             USER-SET VARIABLE
REM ---------------------------------------------------------------------------
REM Set the VCB framework path here. This must be set in order for this script
REM to run properly.

set VCB_FRAMEWORK_PATH=c:\vcb_framework



REM ---------------------------------------------------------------------------
REM                                ACTIVATION
REM ---------------------------------------------------------------------------
REM Activate this VCB_RetroEventHandler script by placing it in the same folder
REM as the Retrospect Config file.
REM For XP/2003: c:\Documents and Settings\All Users\Application Data\Retrospect\
REM For Vista/7/2008: c:\Users\All Users\Retrospect\



REM ---------------------------------------------------------------------------
REM                   DO NOT MODIFY THE CODE BELOW THIS POINT
REM ---------------------------------------------------------------------------
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
REM The following statement will appear when this Event Handler is opened in
REM the Windows Explorer.
If NOT {%1}=={} goto :ENDMSG
	Echo This is a Retrospect External Script written in the Windows batch
	Echo command language. This script facilitates backup of virtual machines
	Echo through integration with VMware Consolidated Backup. For more information,
	Echo please see the Retrospect 7.7 User's Guide Addendum.
	pause
	goto :EXIT
:ENDMSG
set _PROC=%1
REM echo __debug: Will call %_PROC%
shift
goto :%_PROC%


REM -- Begin PreStartSource ------------------------------------------------------

:PreStartSource
set scriptName=%1
set volName=%~n2
set sourcePath=%3 
set clientName=%4 
set interventionFile=%5

REM -- Replace the following lines with your PreStartSource procedure
echo Retrospect script %scriptName% will prestart back up volume %volName% at %sourcePath% on %clientName%
mkdir %sourcePath%
goto :EXIT REM -- End PreStartSource
REM ---------------------------------------------------------------------------


REM -- Begin StartSource ------------------------------------------------------

:StartSource
set scriptName=%1
set volName=%~n2
set sourcePath=%3 
set clientName=%4 
set interventionFile=%5

REM -- Replace the following lines with your StartSource procedure
echo Retrospect script %scriptName% will back up volume %volName% at %sourcePath% on %clientName%

REM volName is set above with quotes removed (%~2) and path removed (%~n2)
REM Determine if this source is to be an image or file backup
REM image backups have sources named with "-fullVM" at end

REM parse last 7 chars of this source
set volNameEnd=%volName:~-7%
REM echo __debug: volNameEnd is %volNameEnd%
if "%volNameEnd%" == "-fullVM" (
	REM want image-level backup
	set vcbSourceName=%volName:~0,-7%
	set vcbBackupType=fullvm
	goto :ENDVOLNAMECHECK
) else (
	REM want file-level backup
	set vcbSourceName=%volName%
	set vcbBackupType=file
	goto :ENDVOLNAMECHECK
)

REM assume this was a file backup
set vcbSourceName=%volName%
set vcbBackupType=file

:ENDVOLNAMECHECK
REM echo __debug: VCB_StartSource: will call pre-command script for %vcbSourceName% %vcbBackupType%
echo.
echo Mounting the volume, please wait . . .
echo.
cscript.exe "%VCB_FRAMEWORK_PATH%\generic\pre-command.wsf" "%VCB_FRAMEWORK_PATH%" "%vcbSourceName%" "%vcbBackupType%"

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


REM -- EndSource procedure

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

REM echo __debug: VCB_EndSource_cleanup: will run cleanup script for %sourceName%
"%VCB_FRAMEWORK_PATH%\vcbCleanup.bat" -y

goto :EXIT REM -- End EndSource
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
REM	pause
	goto :endif_EndScript
:else_NonFatalEndScript
	if %fatalErrCode%=="0" goto :else_NoErrorsEndScript
	echo Retrospect script %scriptName% finished with %numErrors% non-fatal errors.
REM	pause
	goto :endif_EndScript
:else_NoErrorsEndScript
	echo Retrospect script %scriptName% finished with no errors
REM	pause
:endif_EndScript

REM echo VCB_EndScript_cleanup: will run cleanup script for %scriptName%
"%VCB_FRAMEWORK_PATH%\vcbCleanup.bat" -y

goto :EXIT REM -- End EndScript
REM ---------------------------------------------------------------------------


REM stub procedure tags
:StartApp
:EndApp
:StartBackupServer
:StopBackupServer
:StartScript
:MediaRequest
:TimedOutMediaRequest
:ScriptCheckFailed
:NextExec
:StopSched
:PasswordEntry


:EXIT

REM ---------------------------------------------------------------------------
REM (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
REM ---------------------------------------------------------------------------
