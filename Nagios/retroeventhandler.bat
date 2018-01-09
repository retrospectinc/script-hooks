@echo off
REM
REM Sample Retrospect Event Handler for Nagios
REM 
REM     This batch file will notify a Nagios monitoring system using the
REM open source Perl send_nrdp plugin.
REM
REM Download the plugin from:
REM https://exchange.nagios.org/directory/Addons/Passive-Checks/send_nrdp-Perl-Client/details
REM
REM     In addition, you will need to fill out the setting section below.
REM
REM (C) Retrospect, Inc.
REM 

REM Settings needed to send Nagios notifications. The default is the same path as this file.
set NRDP_CLIENT_PATH=.\send_nrdp.pl

REM The following settings tells the NRDP client
REM how to communicate with the NRDP notification servder.
set NAGIOS_NRDP_SERVER=
set NAGIOS_URL=
set NAGIOS_TOKEN=
set NAGIOS_HTTP_USER=
set NAGIOS_HTTP_PASSWD=

REM The following is used as the Retrospect hostname and service name in the notification
set RETROSPECT_HOSTNAME=My Retrospect IP address
set RETROSPECT_SERVICE_NAME=Retrospect

REM To test this script, run the following in the command line
REM retroEventHandler.bat EndScript "Daily Backup" "7" "-530" "backup client not found"


REM The rest of the code should not need to be modified.
If NOT {%1}=={} goto :ENDMSG
	echo     This batch file will will notify the Nagios monitoring system.
	echo     To use this file, copy it to the Retrospect directory.
	pause
	goto :RETURN_OK
:ENDMSG
set _PROC=%1
shift
goto :%_PROC%


REM -- Begin EndScript --------------------------------------------------------
:EndScript 
REM Interpret variables from parameters while removing any quotations
set scriptName=%~1
set numErrors=%~2
set fatalErrCode=%~3
set fatalErrMsg=%~4

REM Send either a OK, warning or error state notification based on 
REM fatal error code and number of errors.
if %fatalErrCode%=="0" goto :else_NonFatalEndScript
	call :SendNotification 2, "Script: %scriptName% - Fatal Error #%fatalErrCode% %fatalErrMsg%"
	goto :endif_EndScript
:else_NonFatalEndScript
	if %numErrors%=="0" goto :else_NoErrorsEndScript
	call :SendNotification 1, "%scriptName%: Finished with %numErrors% errors"
	goto :endif_EndScript
:else_NoErrorsEndScript
	call :SendNotification 0, OK
:endif_EndScript
goto :RETURN_OK
REM  -- End EndScript --------------------------------------------------------

REM -- SendNotification function ---------------------------------------------
REM Note this uses Perl and the NAGIOS_xxx settings set above
:SendNotification
set state=%~1
set output=%~2

set NAGIOS_NOTIFICATION=%RETROSPECT_HOSTNAME%;%RETROSPECT_SERVICE_NAME%;%state%;%output%

echo %NAGIOS_NOTIFICATION% | "perl.exe" "%NRDP_CLIENT_PATH%" -H %NAGIOS_NRDP_SERVER% -url %NAGIOS_URL% -d ";" -token %NAGIOS_TOKEN% -http_user %NAGIOS_HTTP_USER% -http_pass %NAGIOS_HTTP_PASSWD%

goto :EOF
REM -- SendNotification function (end)----------------------------------------


REM stub procedure tags
:StartApp
:EndApp
:StartBackupServer
:StopBackupServer
:StartScript
:StartSource
:StopSource
:MediaRequest
:TimedOutMediaRequest
:ScriptCheckFailed
:NextExec
:StopSched
:PasswordEntry

:RETURN_OK
:EOF