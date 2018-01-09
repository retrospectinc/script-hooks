'
' RetroEventHandler.vbs
'
'	  Sample VBScript event handler for the Retrospect application.
'
'
' Sample call:
' wscript RetroEventHandler.vbs "StartApp" "12/14/99 16:32 PM" "true" "c:/test"
'
'Copyright 2000-2006
'

Option Explicit

REM To integrate Retrospect with Slack, first create an incoming webhook
REM c.f. https://my.slack.com/services/new/incoming-webhook/
dim slackURL
slackURL="https://hooks.slack.com/services/Txxxxxxxx/Bxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx"


dim WshShell
Set WshShell = WScript.CreateObject("WScript.Shell")

dim msgDivider
msgDivider = ":" & vbCrLf & vbCrLf

Call HandleEvent()

' TimeZone
'     Return the current timezone as minutes from UTC.
'
function TimeZone
    dim tz, os
    for each os in GetObject("winmgmts:").InstancesOf ("Win32_OperatingSystem")
        TimeZone= os.CurrentTimeZone
        exit for
    next
end function


' TimeStamp
'     Return time and date as a GMT Unix filetime.
'
function TimeStamp
    Dim nowInGMT, zeroDate
    nowInGMT = DateAdd("n", -1* TimeZone, Now)   ' convert current time to GMT
    zeroDate = DateSerial(1970,1,1)              ' beginning of unix file time
    TimeStamp= DateDiff("s", zeroDate, nowInGMT) ' return seconds from zero to now
end function


' PostToSlack
'     Post a message to Slack.
'
function PostToSlack(title, text, color, fields)
    dim fallback, pretext, message
	
	title = Replace(title, "\", "\\")
	text = Replace(text, "\", "\\")
	
    fallback = title & "-" & text
    pretext = ""
    fields="[" & fields & "]"

    message = "{" & _
            """username"": ""Retrospect""," & _
            """icon_url"": ""http://download.retrospect.com/site/cube_128.png""," & _
            """attachments"": [" & _
                "{" & _
                    """fallback"": """ & fallback &"""," & _
                    """color"": """ & color &"""," & _
                    """pretext"": """ & pretext &"""," & _
                    """title"": """ & title &"""," & _
                    """text"": """ & text &"""," & _
                    """fields"": " & fields &"," & _
                    """footer_icon"": ""http://download.retrospect.com/site/cube_32.png""," & _
                    """footer"": ""Retrospect, Inc.""," & _
                    """ts"": " & TimeStamp() & "" & _
                "}" & _
            "]" & _
        "}"
    
    dim xmlhttp 
    set xmlhttp = Createobject("MSXML2.ServerXMLHTTP")
    xmlhttp.Open "POST", slackURL, false
	xmlhttp.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
    
	xmlhttp.send "payload=" & message
	' WScript.Echo message REM For debugging
	' WScript.Echo xmlhttp.responseText
	PostToSlack = xmlhttp.responseText
    set xmlhttp = nothing
End function


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


'
' StartApp
'	  Sent when Retrospect launches. wasAutoLaunched is true if Retrospect was
' launched automatically to run a scheduled script.
'
Sub StartApp(startDate, wasAutoLaunched, interventionFile)
	Dim msg, title
    
    title = "Retrospect started"
	If (wasAutoLaunched) Then
		msg = "Retrospect autolaunched on " & startDate & "."
	Else
		msg = "Retrospect launched on " & startDate & "."
	End If
	PostToSlack title, msg, "", ""
End Sub


'
' EndApp
'	  Sent when Retrospect is quitting.
'
Sub EndApp(endDate)
	Dim msg, title
	
    title = "Retrospect exited"
	msg = "Retrospect quit on " & endDate & "."
	PostToSlack title, msg, "", ""
End Sub


'
' StartBackupServer
'	  Sent when the BackupServer is started via either a script or manually.
' Return false to prevent backup server starting
'
Sub StartBackupServer(startDate, interventionFile)
	Dim msg, title
	
    title = "Proactive Backup Server Started"
	msg = "Retrospect Backup Server started on " & _
		startDate & "."
		
    PostToSlack title, msg, "", ""
End Sub


'
' StopBackupServer
'	  Sent when Backup Server stops.
'
Sub StopBackupServer(endDate)
	Dim msg, title
	
    title = "Proactive Backup Server Stopped"
	msg =  "Retrospect Backup Server stopped on " & endDate & "."
	PostToSlack title, msg, "", ""
End Sub


'
' StartScript
'	  Sent when a script is run, either manually or as part of a scheduled
' execution. Return false to prevent script starting
'
Sub StartScript(scriptName, startDate, interventionFile)
	Dim msg, title
	
    title = "Script '" & scriptName & "' started"
	msg = "Retrospect script '" & scriptName & "' started " & _
		startDate & "."

	PostToSlack  title, msg, "", ""
End Sub


'
' EndScript
'	  Sent when a script finishes.
' numErrors is the total number of errors that occured. fatalErrCode is zero if
' the script was able to complete, otherwise it is a negative number for the
' error that caused the script to abort execution. fatalErrMsg is "successful" if
' there was no fatal error, otherwise it is the description of the error.
'
Sub EndScript(scriptName, _
	numErrors, _
	fatalErrCode, _
	fatalErrMsg)
	Dim msg, title, fields, color
	
    title = "Script '" & scriptName & "' finished"
	msg = "Retrospect script '" & scriptName & "' finished"
    fields = ""
				
	If (fatalErrCode <> 0) Then
        fields = "{" & _
                """title"": ""Errors""," & _
                """value"": """ & numErrors & """," & _
                """short"": true" & _
            "}," & _
            "{" & _
                """title"": ""Error Code""," & _
                """value"": """ & fatalErrCode & """," & _
                """short"": true" & _
            "}," & _
            "{" & _
                """title"": ""Error Message""," & _
                """value"": """ & fatalErrMsg & """," & _
                """short"": false" & _
            "}"
            color = "danger"
		msg = msg & "." & vbCrLf & "The script was stopped by " & _
		FormatError(fatalErrCode, fatalErrMsg) & "."
	ElseIf (numErrors = 0) Then
		msg = msg & " with no errors."
        color = "okay"
	ElseIf (numErrors = 1) Then
		msg = msg & " with one non-fatal error."
        color = "warning"
	Else
		msg = msg & " with " & FormatNumber(numErrors,0) & " non-fatal errors."
        color = "warning"
	End If
	
	PostToSlack title, msg, color, fields
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
	Dim title
	
	
	myComputerName = "My Computer"
	title = "Source '" & sourceName & "' started"
	If (Left(sourceName, Len(myComputerName)) = myComputerName) Then
		sourceName = Right(sourceName, Len(sourceName) - Len(myComputerName) - 1)
		msg = "The local volume '" & sourceName & "' at " & sourcePath & _
		" is about to be backed up by script '" & scriptName &"'."
	Else
		msg = "Client '" & clientName & "'s' volume, '" & sourceName & "' at " & _
			sourcePath & " is about to be backed up by script '" & scriptName & "'."
	End If
	
	' WshShell.Popup title & "--" & msg
	PostToSlack title, msg, "", ""
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
	fatalErrMsg)
	Dim myComputerName, sourceDescription
	Dim msg, title, fields, color

	myComputerName = "My Computer"
	title = "Source '" & sourceName & "' finished"
	
	' Volume/Client
	If (Left(clientName, Len(myComputerName)) = myComputerName) Then
		sourceName = Right(sourceName, Len(sourceName) - Len(myComputerName) - 1)
		sourceDescription = "local volume '" & sourceName & "' at " & sourcePath
	Else
		sourceDescription = "client '" & clientName & "'s' volume, '" & sourceName & _
			"' at " & sourcePath
	End If
    
    fields = "{" & _
        """title"": ""Destination""," & _
        """value"": """ & backupSet & """," & _
        """short"": false" & _
    "},{" & _
        """title"": ""Files""," & _
        """value"": """ & FormatNumber(numFiles, 0) & """," & _
        """short"": true" & _
    "},{" & _
        """title"": ""KB""," & _
        """value"": """ & FormatNumber(KBBackedUp, 0) & "KB" & """," & _
        """short"": true" & _
    "},{" & _
        """title"": ""Duration""," & _
        """value"": """ & FormatSeconds(durationInSecs) & """," & _
        """short"": true" & _
    "},{" & _
        """title"": ""Finished""," & _
        """value"": """ & backupStopDate & """," & _
        """short"": true" & _
    "}"
	
	msg = "Script '" & scriptName & "' finished a " & backupAction & _
		" backup of " & sourceDescription & " to " & backupSet
	' Errors
	If (fatalErrCode <> 0) Then
        fields = fields & ",{" & _
                """title"": ""Errors""," & _
                """value"": """ & numErrors & """," & _
                """short"": true" & _
            "}," & _
            "{" & _
                """title"": ""Error Code""," & _
                """value"": """ & fatalErrCode & """," & _
                """short"": true" & _
            "}," & _
            "{" & _
                """title"": ""Error Message""," & _
                """value"": """ & fatalErrMsg & """," & _
                """short"": false" & _
            "}"
            color = "danger"
		msg = msg & " stopped by " & FormatError(fatalErrCode, fatalErrMsg) & "."	
	ElseIf (numErrors = 0) Then
        color = "okay"
		msg = msg & " successfully."
	ElseIf (numErrors = 1) Then
        color = "warning"
		msg = msg & " with one non-fatal error."
	Else
        color = "warning"
		msg = msg & " with " & FormatNumber(numErrors, 0) & " non-fatal errors."
	End If
	
	PostToSlack title, msg, color, fields
End Sub


'
' MediaRequest
'
'     Sent before Retrospect requests media needed for a backup.
'
'

Sub MediaRequest(mediaLabel, _
	mediaName, _
	mediaIsKnown, _
	secondsWaited, _
	interventionFile)
	Dim title, msg
	
    title = "Media Request"
	msg = "Retrospect is requesting media '" & mediaName & "' (" & mediaLabel & ")"
	If (mediaIsKnown) Then
		msg = msg & vbCrlf & "Retrospect has backed up to this media before."
	Else
		msg = msg & vbCrlf & "This is either a new or unknown media."
	End If
	msg = msg & vbCrlf & "Retrospect has waited " & FormatSeconds(secondsWaited*60) & " so far."
	
	PostToSlack title, msg, "warning", ""
End Sub


'
' TimedOutMediaRequest
'
'     Sent before Retrospect times out on waiting for a media request. Note that
' the "Media Request Timeout" option in the preferences must be turned on to
' receive this event.
'
'

Sub TimedOutMediaRequest(mediaLabel, _
	mediaName, _
	mediaIsKnown, _
	secondsWaited, _
	interventionFile)
	Dim msg, title
	
    title = "Media Request time out"
	msg = "Retrospect's media request for '" & mediaName & "' (" & mediaLabel & _
		") timed out after waiting " & FormatSeconds(secondsWaited*60) & "."
	
	PostToSlack title, msg, "danger", ""
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
	fatalErrMsg)
	Dim msg, title
	
    title = "Script '" & scriptName & "' not ready"
	msg = "ScriptCheckFailed" & msgDivider & _
		"The Retrospect script '" & scriptName & "' will not run on " & _
		nextDate & vbCrLf & _
		FormatError(errCode, fatalErrMsg) & "." & vbCrLf & _
		"Retrospect's dialog: '" & reason & "'"
	PostToSlack title, msg, "", ""
End Sub


'
' NextExec
'
'     Sent before Retrospect quits when the next script to execute is able to
' run. "Check validity of next script" must be checked in Retrospect's
' preferences (Notification:Alerts) to receive this event.
'

Sub NextExec(scriptName, nextDate)
	Dim msg, title
	
	title = "Script '" & scriptName & "' next to run"
	msg = "Script '" & scriptName & "' is ready to run on " & _
		nextDate & "."
	PostToSlack title, msg, "", ""
End Sub


'
' StopSched
'
'     Sent when an unattended script is scheduled to stop. Return false to keep
' script running.
'

Sub StopSched(scriptName, schedStopDate, interventionFile)
	Dim msg, title

	title = "Script '" & scriptName & "' stopping before finished"
	msg = "Script '" & scriptName & "' was stopped as per schedule on " & _
		schedStopDate & "."
        
	PostToSlack title, msg, "", ""
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
	fatalErrMsg)
	Dim msg, title, color
	
	If (errCode <> 0) Then
        title = "Retrospect login failed!"
        color = "danger"
		msg = "Login failed after " & FormatNumber(attempts, 0) & _
			" attempts (error #" & errCode & " - " & fatalErrMsg & ")" & "." & _
			vbCrLf & "Retrospect's dialog: " & actionString & ""
	ElseIf (attempts = 1) Then
        title = "Retrospect login successful"
        color = "okay"
		msg = "Login successful" & vbCrLf & "Retrospect's dialog: " & _
			actionString & ""
	Else
        title = "Retrospect login successful"
        color = "warning"
		msg = "Login successful after " & FormatNumber(attempts, 0) & _
			" attempts." & vbCrLf & "Retrospect's dialog: " & actionString &_
			""
	End If
	PostToSlack title, msg, "", ""
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
	fatalErrMsg, _
	errZone, _
	interventionFile)
	
	Dim msg, title, fields

    title = "Fatal Error"
    fields="{" & _
        """title"": ""Message""," & _
        """value"": """ & reason & """," & _
        """short"": false" & _
    "}"
	msg = "Script '" & scriptName & "' failed (" & errZone & _
		") " & FormatError(errCode, fatalErrMsg)
	PostToSlack title, msg, "danger", fields
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
		WshShell.Popup "This is a sample Retrospect external script written in VBScript for Slack." & _
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
	' WshShell.Popup debugArgs								' Uncomment for debugging
	
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
