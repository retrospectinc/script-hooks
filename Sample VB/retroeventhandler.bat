@echo off
REM
REM	     Sample Retrospect Event Handler
REM To use the sample Visual Basic event handler, both RetroEventHandler.bat and 
REM SampleRetroEventHandler need to be installed.
REM 
REM      To overcome the inherent limitations of Visual Basic, The VB version of 
REM RetroEventHandler comes in two files: RetroEventHandler.bat and 
REM SampleRetroEventHandler.exe. 
REM 
REM      Since Visual Basic does not have the ability to pass on a return value
REM upon exiting, it instead creates a file to indicate any return value. 
REM RetroEventHandler.bat calls SampleRetroEventHandler.exe and checks for the 
REM existence of the file "returnCancel" upon the completion of 
REM SampleRetroEventHandler.exe.
REM
REM (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
REM 


REM "c:\durango\doutput\retroeventhandler.bat" StartApp "12/1/99 11:30 AM" "true"

If NOT {%1}=={} goto :ENDIF
	Echo      This file works in conjunction with Visual Basic event handlers. To
	Echo use this file, copy it to the Retrospect application directory. 
	pause
	exit
:ENDIF


set a=%1
shift
set b=%1
shift
set c=%1
shift
set d=%1
shift
set e=%1
shift
set f=%1
shift
set g=%1
shift
set h=%1
shift
set i=%1
shift
set j=%1
shift
set k=%1
shift
set l=%1
shift
set m=%1
shift
set n=%1
shift
set o=%1
shift
set p=%1
shift
set q=%1

"SampleRetroEventHandler" %a% %b% %c% %d% %e% %f% %g% %h% %i% %j% %k% %l% %m% %n% %o% %p% %q%

If NOT Exist returnCancel goto :RETURN_OK


REM We need to delete the file created by the VB app and then generate an error
REM that will be interpreted by Retrospect as a "Cancel Event" message

del returnCancel

REM The error condition is set by the last line executed.
REM Therefore, to return an error, execute an illegal command such as...
This is not a legal command 2>%temp%\errorTxt.txt

:RETURN_OK