@echo off
REM
REM Retrospect Event Handler - Lotus Domino Server
REM 
REM     This batch file will stop a Lotus Domino server running as an application 
REM when a Retrospect script named "Backup Domino" is run. It will restart the 
REM server after the script is finished.
REM
REM	Lotus Domino Server will shut down. A consistancy check will be performed
REM on Domino Server files and databases will be compacted before Retrospect backs
REM up the volume specified.
REM
REM	This Event Handler requires the Microsoft Windows Resource Kit loaded
REM to operate properly.
REM
REM (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
REM 

REM --------------------------------------------------------------------------

REM Configure the following lines to match your Domino Server setup.

REM Set path to the Domino Server directory.
set dominoPath=C:\Path\To\Server

REM Set the version of Domino Server. (ex. 5.0=500 or 5.0.2a=502, etc.)
set dominoVers=500

REM --------------------------------------------------------------------------


REM The following code branches to the procedure labels below, it should not be
REM modified.
If NOT {%1}=={} goto :ENDMSG
	echo     This batch file will stop a Lotus Domino server running as an 
	echo application when a Retrospect script named "Backup Domino" is run. 
	echo It will restart the Domino Server after the script is finished.
	echo      To use this file, copy it to the Retrospect directory.
	pause
	goto :RETURN_OK
:ENDMSG

If NOT {"%dominoPath%"}=={"C:\Path\To\Server"} goto :ENDWARNING
	echo     You must first set the path of your Domino Server
	echo directory. This is necessary for this script to know
	echo where your Domino Server application is located. This
	echo setting is located in the top portion of this script.
	pause
	goto :RETURN_OK
:ENDWARNING

set _PROC=%1
shift
goto :%_PROC%


REM -- Begin StartSource------------------------------------------------------
:StartSource
set scriptName=%1

REM Configure to match Retrospect script name.
if {%scriptName%}=={"Backup Domino"} call :PAUSE_DOMINO_SERVER
goto :RETURN_OK REM -- End StartSource
REM ---------------------------------------------------------------------------


REM -- Begin EndSource --------------------------------------------------------
:EndSource 
set scriptName=%1

if {%scriptName%}=={"Backup Domino"} call :CONTINUE_DOMINO_SERVER

goto :RETURN_OK REM -- End EndSource 
REM ---------------------------------------------------------------------------


:PAUSE_DOMINO_SERVER

REM The Event Handler will first shutdown the Domino Server via nserver -q,
REM and then go to sleep for 5 minutes, after which time it will wake up
REM and pull down a list of the Domino server pid's and write it out to a
REM file in TEMP directory called pid.lst. It will then go out and parse
REM this file and then do a Kill -f PID on all the pid's listed in the file.
REM After the Domino Server tasks are cleaned up, it will then
REM do a nfixup & Ncompact.

echo Attempting to Shutdown the Domino Server

REM The next line will tell the Lotus Domino Server to shutdown and then
REM continue on with the script.

start "Domino Server Shutdown" /b %dominoPath%\nserver -q

sleep 300

pulist | findstr /I /C:"nadminp.exe" >%temp%\pid.lst
pulist | findstr /I /C:"naldaemn.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"namgr.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ncalconn.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ncatalog.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nchronos.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ncollect.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ncompact.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nconvert.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ndesign.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ndrt.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ndsmgr.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nevent.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nfixup.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nhttp.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nhttpcgi.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nimap.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nimsgcnv.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nisesctl.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"niseshlr.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nldap.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nlivecs.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nlnotes.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nlogin.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nmaps.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nnntp.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nnsadmin.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nobject.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nomsgcnv.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nosesctl.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"noseshlr.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"notes.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"npop3c.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"npop3.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nreport.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nrouter.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nreplica.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nsapdmn.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nsmtpmta.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nstatlog.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nstats.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nsched.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nservice.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nserver.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ntsvinst.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nupdate.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nupdall.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nwrdaemn.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nweb.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nxpcdmn.exe" >>%temp%\pid.lst

REM ccMTA processes
pulist | findstr /I /C:"nccmta.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"ncctctl.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccmctl.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccttcp.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccbctl.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccmin.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccmout.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccdctl.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccdin.exe" >>%temp%\pid.lst
pulist | findstr /I /C:"nccdout.exe" >>%temp%\pid.lst

REM Third party products need to be hard coded into the script for example:
REM Lotus NotesView's interceptor add in task would be as follows.
REM
REM pulist | findstr /C:"NINTRCPT.EXE" >>%temp%\pid.lst

REM
REM Lotus Notes DFS executables would be as follows.
REM
REM pulist | findstr /I /C:"lfs.EXE" >>%temp%\pid.lst
REM pulist | findstr /I /C:"lfsfax.EXE" >>%temp%\pid.lst

for /f "tokens=2" %%I in (%temp%\pid.lst ) do kill -f %%I

echo Begining Fixup of Databases
REM You must run nfixup before running compact or updall in case the server is 
REM in hang state, you need to run fixup to clean up all the abnormally 
REM terminated databases.
%dominoPath%\nfixup

echo Begining Compact of Databases
REM You can specify an alternate arguements to the ones specified.
REM For Domino Server version 5 or later.
if %dominoVers% GEQ 500 %dominoPath%\ncompact -b
REM For Domino Server version 4.5x and 4.6x.
if %dominoVers% LSS 500 %dominoPath%\ncompact -s 15

Sleep 150

goto :RETURN_OK

:CONTINUE_DOMINO_SERVER

echo Starting Domino Server
start "Domino Server Startup" /b %dominoPath%\nserver

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



