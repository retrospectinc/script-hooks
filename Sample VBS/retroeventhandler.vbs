'
' RetroEventHandler.vbs
'
'	  Sample VBScript event handler for the Retrospect application.
'
'
' Sample call:
' wscript RetroEventHandler.vbs "StartApp" "12/14/99 16:32 PM" "true"
'
'Copyright 2000-2006
'

Option Explicit


dim WshShell
Set WshShell = WScript.CreateObject("WScript.Shell")

dim msgDivider
msgDivider = ":" & vbCrLf & vbCrLf

Call HandleEvent()


' FormatError
'	  Return a string for the passed in error code and error string.
' This is a utility function for the scripts below.
'
Function FormatError(errCode, errMsg)
	FormatError = "error #" & errCode & " (" & errMsg & ")"
End Function


'
' FormatSeconds
'     Return a string representing the passed in number of seconds.
' E.g.
'     "3 hours 1 minute"
'     "2 hours 2 seconds"
'
Function FormatSeconds(secondsStr)
	dim secStr
	dim seconds

	' convert string to number of seconds
	seconds = 0
	On Error Resume Next
	seconds = 1 * secondsStr
	On Error GoTo 0

	secStr = ""
	If (seconds >= 86400 * 2) Then
		secStr = secStr & (seconds \ 86400) & " days "
		seconds = seconds mod 86400
	ElseIf (seconds >= 86400) Then
		secStr = secStr  & "1 day "
		seconds = seconds mod 86400
	End If

	If (seconds >= 3600 * 2) Then
		secStr = secStr & (seconds \ 3600) & " hours "
		seconds = seconds mod 3600
	ElseIf (seconds >= 3600) Then
		secStr = secStr  & "1 hour "
		seconds = seconds mod 3600
	End If

	If (seconds >= 60 * 2) Then
		secStr = secStr & (seconds \ 60) & " minutes "
		seconds = seconds mod 60
	ElseIf (seconds >= 60) Then
		secStr = secStr & "1 minute "
		seconds = seconds mod 60
	End If

	If (seconds >= 2) Then
		secStr = secStr & seconds & " seconds "
	ElseIf (seconds = 1) Then
		secStr = secStr & "1 second "
	End If
	
	If (Len(secStr) > 2) Then
		FormatSeconds = Left(secStr, Len(secStr) - 1)
	Else
		FormatSeconds = "0 seconds"
	End If
End Function


' ReturnResult
'     If result is false, create a file to inform the caller we wish to abort.
' Quit when done.
'
Sub ReturnResult(msg, interventionFile)
	Dim fs, f
    
	Set fs = CreateObject("Scripting.FileSystemObject")
	Set f = fs.CreateTextFile(interventionFile)
	f.Write msg
	f.Close
End Sub



'
' StartApp
'	  Sent when Retrospect launches. wasAutoLaunched is true if Retrospect was
' launched automatically to run a scheduled script.
'
Sub StartApp(startDate, wasAutoLaunched, interventionFile)
	Dim msg
	Dim btnClicked

	If (wasAutoLaunched) Then
		msg = "StartApp" & msgDivider & _
			"Retrospect is autolaunching on " & startDate & "."
	Else
		msg = "StartApp" & msgDivider & _
			"Retrospect is launching on " & startDate & "."
	End If
	msg = msg & vbCrLf & "Let Retrospect launch?"
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:StartApp", 1)
	
	
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "Retrospect launch stopped by external script.", interventionFile
	End if
End Sub


'
' EndApp
'	  Sent when Retrospect is quitting.
'
Sub EndApp(endDate)
	Dim msg
	
	msg = "EndApp" & msgDivider & _
		"Retrospect quit on " & endDate & "."
	WshShell.Popup msg, 120, "RetroEventHandler:EndApp", 0
End Sub


'
' StartBackupServer
'	  Sent when the BackupServer is started via either a script or manually.
' Return false to prevent backup server starting
'
Sub StartBackupServer(startDate, interventionFile)
	Dim msg
	Dim btnClicked
	
	msg = "StartBackupServer" & msgDivider & _
		"Retrospect Backup Server is starting on " & _
		startDate & "." & vbCrLf & _
		"Let Backup Server run?"
		
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:StartBackupServer", 1)
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "Backup Server stopped by external script", interventionFile
	End if
End Sub


'
' StopBackupServer
'	  Sent when Backup Server stops.
'
Sub StopBackupServer(endDate)
	Dim msg
	
	msg =  "StopBackupServer" & msgDivider & _
		"Retrospect Backup Server stopped on " & endDate & "."
	WshShell.Popup msg, 120, "RetroEventHandler:StopBackupServer", 0
End Sub


'
' StartScript
'	  Sent when a script is run, either manually or as part of a scheduled
' execution. Return false to prevent script starting
'
Sub StartScript(scriptName, startDate, interventionFile)
	Dim msg
	Dim btnClicked
	
	msg = "StartScript" & msgDivider & _
		"Retrospect script '" & scriptName & "' is starting on " & _
		startDate & "." & vbCrLf & _
		"Let script run?"

	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:StartScript", 1)
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "Script is stopped by external script" , interventionFile
	End if
End Sub


'
' EndScript
'	  Sent when a script finishes.
' numErrors is the total number of errors that occured. fatalErrCode is zero if
' the script was able to complete, otherwise it is a negative number for the
' error that caused the script to abort execution. errMsg is "successful" if
' there was no fatal error, otherwise it is the description of the error.
'
Sub EndScript(scriptName, _
	numErrors, _
	fatalErrCode, _
	errMsg)
	Dim msg
	
	msg = "EndScript" & msgDivider & "Retrospect script '" & scriptName & "' finished"
				
	If (fatalErrCode <> 0) Then
		msg = msg & "." & vbCrLf & "The script was stopped by " & _
		FormatError(fatalErrCode, errMsg) & "."
	ElseIf (numErrors = 0) Then
		msg = msg & " with no errors."
	ElseIf (numErrors = 1) Then
		msg = msg & " with one non-fatal error."
	Else
		msg = msg & " with " & FormatNumber(numErrors,0) & " non-fatal errors."
	End If
	
	WshShell.Popup msg, 120, "RetroEventHandler:EndScript", 0
End Sub


' StartSource
'	  Sent immediately before a script backs up a source volume.
' sourceName is the volume name that is being backed up, it will be prefaced
' with "My Computer\" if it is a local volume or the clientName otherwise.
' sourcePath is the file system path of the volume.
'

Sub StartSource(scriptName, sourceName, sourcePath, clientName, interventionFile)
	Dim myComputerName
	Dim msg
	Dim btnClicked

	myComputerName = "My Computer"
	msg = "StartSource" & msgDivider
	If (Left(sourceName, Len(myComputerName)) = myComputerName) Then
		sourceName = Right(sourceName, Len(sourceName) - Len(myComputerName) - 1)
		msg = msg & "The local volume '" & sourceName & "' at " & sourcePath & _
		" is about to be backed up by script '" & scriptName &"'."
	Else
		msg = msg & "Client '" & clientName & "'s' volume, '" & sourceName & "' at " & _
			sourcePath & " is about to be backed up by " & scriptName & "."
	End If
	
	msg = msg & vbCrLf & "Let source start?"
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:StartSource", 1)
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "source skipped by external script", interventionFile
	End if
End Sub


'
' EndSource
'
'     Sent after a script has completed backing up a source. As above, sourceName
' is prefaced with either the client name or "My Computer\".
'

Sub EndSource( _
	scriptName, _
	sourceName, _
	sourcePath, _
	clientName, _
	KBBackedUp, _
	numFiles, _
	durationInSecs, _
	backupStartDate, _
	backupStopDate, _
	scriptStartDate, _
	backupSet, _
	backupAction, _
	parentVolume, _
	numErrors, _
	fatalErrCode, _
	errMsg)
	Dim myComputerName
	Dim msg

	myComputerName = "My Computer"
	msg = "EndSource" & msgDivider
	
	' Volume/Client
	If (Left(clientName, Len(myComputerName)) = myComputerName) Then
		sourceName = Right(sourceName, Len(sourceName) - Len(myComputerName) - 1)
		msg = msg & "The local volume '" & sourceName & "' at " & sourcePath
	Else
		msg = msg & "Client '" & clientName & "'s' volume, '" & sourceName & _
			"' at " & sourcePath
	End If
	
	' Errors
	If (fatalErrCode <> 0) Then
		msg = msg & " stopped by " & FormatError(fatalErrCode, errMsg) & "."	
	ElseIf (numErrors = 0) Then
		msg = msg & " completed successfully."
	ElseIf (numErrors = 1) Then
		msg = msg & " completed with one non-fatal error."
	Else
		msg = msg & " completed with " & FormatNumber(numErrors, 0) & " non-fatal errors."
	End If
	msg = msg & vbCrlf & "Script '" & scriptName & "' finished a " & backupAction & _
		" backup to '" & backupSet & "'. " & FormatNumber(numFiles, 0) & _
		" files (" & FormatNumber(KBBackedUp, 0) & "KB) were backed up in " & _
		FormatSeconds(durationInSecs) & "." & vbCrlf
	msg = msg & "The script started on " & scriptStartDate & _
		" and the backup started on " & backupStartDate & _
		" and finished on " & backupStopDate & "."
	
	WshShell.Popup msg, 120, "RetroEventHandler:EndSource", 0
End Sub


'
' MediaRequest
'
'     Sent before Retrospect requests media needed for a backup.
'
'     Return true to fail media request.
'

Sub MediaRequest(mediaLabel, _
	mediaName, _
	mediaIsKnown, _
	secondsWaited, _
	interventionFile)
	Dim msg
	Dim btnClicked
	
	msg = "MediaRequest" & msgDivider & _
		"Retrospect is requesting media '" & mediaName & "' (" & mediaLabel & ")"
	If (mediaIsKnown) Then
		msg = msg & vbCrlf & "Retrospect has backed up to this media before."
	Else
		msg = msg & vbCrlf & "This is either a new or unknown media."
	End If
	msg = msg & vbCrlf & "Retrospect has waited " & FormatSeconds(secondsWaited*60) & " so far."
	msg = msg & vbCrlf & "Continue with the media request?"
	
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:MediaRequest", 1)
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "Media request aborted by external script.", interventionFile
	End if
End Sub


'
' TimedOutMediaRequest
'
'     Sent before Retrospect times out on waiting for a media request. Note that
' the "Media Request Timeout" option in the preferences must be turned on to
' receive this event.
'
'     Return true to reset timeout request.
'

Sub TimedOutMediaRequest(mediaLabel, _
	mediaName, _
	mediaIsKnown, _
	secondsWaited, _
	interventionFile)
	Dim msg
	Dim btnClicked
	
	msg = "TimedOutMediaRequest" & msgDivider & _
		"Retrospect's media request for '" & mediaName & "' (" & mediaLabel & _
		") is about to time out after waiting " & FormatSeconds(secondsWaited*60) & "." & vbCrLf & _
		"Let Retrospect time out?"
	
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:TimedOutMediaRequest", 1)
	if (btnClicked <> 1) and (btnClicked <> -1)Then
		ReturnResult "TimeOutMediaRequest aborted by external script.", interventionFile
	End if
End Sub


'
' ScriptCheckFailed
'
'     Sent before Retrospect quits when the next script to execute will not be
' able to run. "Check validity of next script" must be checked in Retrospect's
' preferences (Notification:Alerts) to receive this event.
'

Sub ScriptCheckFailed( _
	scriptName, _
	nextDate, _
	reason, _
	errCode, _
	errMsg)
	Dim msg
	
	msg = "ScriptCheckFailed" & msgDivider & _
		"The Retrospect script '" & scriptName & "' will not run on " & _
		nextDate & vbCrLf & _
		FormatError(errCode, errMsg) & "." & vbCrLf & _
		"Retrospect's dialog: '" & reason & "'"
	WshShell.Popup msg, 120, "RetroEventHandler:ScriptCheckFailed", 0
End Sub


'
' NextExec
'
'     Sent before Retrospect quits when the next script to execute is able to
' run. "Check validity of next script" must be checked in Retrospect's
' preferences (Notification:Alerts) to receive this event.
'

Sub NextExec(scriptName, nextDate)
	Dim msg
	
	msg = "NextExec" & msgDivider
	msg = msg & "Script '" & scriptName & "' is scheduled to run on " & _
		nextDate & "."
	WshShell.Popup msg, 120, "RetroEventHandler:NextExec", 0
End Sub


'
' StopSched
'
'     Sent when an unattended script is scheduled to stop. Return false to keep
' script running.
'

Sub StopSched(scriptName, schedStopDate, interventionFile)
	Dim msg
	Dim btnClicked

	msg = "StopSched" & msgDivider
	msg = msg & "Script '" & scriptName & "' is scheduled to stop on " & _
		schedStopDate & "."

	msg = msg & vbCrLf & "Let the script stop?"
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:StopSched", 1)
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "Script was not stopped due to intervention by external script.", interventionFile
	End if
End Sub


'
' PasswordEntry
'
'     Sent when a password is entered.
'

Sub PasswordEntry( _
	actionString, _
	attempts, _
	errCode, _
	errMsg)
	Dim msg
	
	msg = "PasswordEntry" & msgDivider
	If (errCode <> 0) Then
		msg = msg & "Login failed after " & FormatNumber(attempts, 0) & _
			" attempts (error #" & errCode & " - " & errMsg & ")" & "." & _
			vbCrLf & "Retrospect's dialog: " & actionString & ""
	ElseIf (attempts = 1) Then
		msg = msg & "Login successful" & vbCrLf & "Retrospect's dialog: " & _
			actionString & ""
	Else
		msg = msg & "Login successful after " & FormatNumber(attempts, 0) & _
			" attempts." & vbCrLf & "Retrospect's dialog: " & actionString &_
			""
	End If
	WshShell.Popup msg, 120, "RetroEventHandler:PasswordEntry", 0
End Sub

'
' FatalBackupError
'
'     Sent when a unrecoverable error is detected, such as a hardware
' failure
'

Sub FatalBackupError( _
	scriptName, _
	reason, _
	errCode, _
	errMsg, _
	errZone, _
	interventionFile)
	
	Dim msg
    	Dim btnClicked
	
	msg = "FatalBackupError" & msgDivider
	msg = msg & "Script '" & scriptName & "' failed in " & errZone & _
		" " & FormatError(errCode, errMsg) & vbCrLf & _
		reason & "." & vbCrLf & _
		"Retrospect's dialog: " & "'" & reason & "'" & vbCrLf & _
		"Do you want to display a modal dialog?"
	btnClicked = WshShell.Popup(msg, 120, "RetroEventHandler:FatalBackupError", 1)
	if (btnClicked <> 1) and (btnClicked <> -1) Then
		ReturnResult "External script prevented the display of a modal dialog.", interventionFile
	End if
End Sub


'
' HandleEvent
'	  Dispatch event to each possible function above.
'

Sub HandleEvent()
	Dim cmdArgs
	Dim eventMsg
	Dim argNo
	Dim debugArgs

	Set cmdArgs = WScript.Arguments
	
	If (cmdArgs.Count < 1) Then
		WshShell.Popup "This is a sample Retrospect external script written in VBScript." & _
		vbCrLf & _
		vbCrLf & "To use this file on the backup server, move it to Retrospect's directory." & _
		vbCrLf & "To use this file on a client machine, copy it to the directory containing" & _
		vbCrLf & "the Retrospect client ('retroclient.exe')."
		Exit Sub
	Else
		eventMsg = cmdArgs(0)
	End If

	' get args for debugging
	debugArgs = "Arguments:"
	For argNo = 0 To cmdArgs.Count - 1
		debugArgs = debugArgs & vbCrlf & FormatNumber(argNo, 0) & ":" & cmdArgs(argNo)
	Next
	'WshShell.Popup debugArgs								' Uncomment for debugging
	
	' Handle event
	Select Case eventMsg
		Case "StartApp"
			StartApp cmdArgs(1), cmdArgs(2) = "true", cmdArgs(3)
		Case "EndApp"
			EndApp cmdArgs(1)
		Case "StartBackupServer"
			StartBackupServer cmdArgs(1), cmdArgs(2)  
		Case "StopBackupServer"
			StopBackupServer cmdArgs(1)
		Case "StartScript"
			StartScript cmdArgs(1), cmdArgs(2), cmdArgs(3)
		Case "EndScript"
			EndScript cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4)
		Case "StartSource"
			StartSource cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5)
		Case "EndSource"
			EndSource cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5), cmdArgs(6), _
				cmdArgs(7), cmdArgs(8), cmdArgs(9), cmdArgs(10), cmdArgs(11), _
				cmdArgs(12), cmdArgs(13), cmdArgs(14), cmdArgs(15), cmdArgs(16)
		Case "MediaRequest"
			MediaRequest cmdArgs(1), cmdArgs(2), cmdArgs(3) = "true", cmdArgs(4), cmdArgs(5)
		Case "TimedOutMediaRequest"
			TimedOutMediaRequest cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5)
		Case "ScriptCheckFailed"
			ScriptCheckFailed cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5)
		Case "NextExec"
			NextExec cmdArgs(1), DateValue(cmdArgs(2))
		Case "StopSched"
			StopSched cmdArgs(1), cmdArgs(2), cmdArgs(3)
		Case "PasswordEntry"
			PasswordEntry cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4)
		Case "FatalBackupError"
			FatalBackupError cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5), cmdArgs(6)
		Case Else
			MsgBox "Unknown command: " & eventMsg
	End Select
End Sub
