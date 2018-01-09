' RetroEventHandler.vbs
'
'	  Event handler to quit Microsoft Outlook before backing it up.
'
' (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
'

Option Explicit

'     To have Microsoft Outlook quit for every Retrospect backup script,
' leave kBackupScripts empty. To only quit when specific scripts run,
' add the names of the backup scripts to kBackupScripts. Use commas to
' delimit the script names, e.g.:
' Const kBackupScripts = "Notebook backups,Daily Backup"
'
Const kBackupScripts = ""

'     Norton's new scriptblocking feature stops a script which tries to
' write to the filesystem. As this is the technique we use to indicate
' that Outlook was running (and that we need to relaunch it), we have
' set the default behavior to not relaunch Outlook after the backup
' completes. Set kRelaunchOutlook to true below to re-enable this feature.
Const kRelaunchOutlook = False

' kSavedOutlookFile is used to record if Outlook was running or not.
Const kSavedOutlookFile = "OutlookInstances.ini"

' HandleEvent handles the different script triggers sent to this file.
Call HandleEvent()

'
' SaveOutlookState
'
'     Save a file to indicate Outlook was running. We will test for this file's 
' existence when the backup script ends to decide if we should relaunch Outlook.
'
Sub SaveOutlookState()
	Dim fso, ts
	Const ForWriting = 2

	On Error Resume Next
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set ts = fso.OpenTextFile(kSavedOutlookFile, ForWriting, True)
	ts.Close
	On Error GoTo 0
End Sub


'
' OpenSavedOutlook
'
Sub OpenSavedOutlook()
	Dim fso
	Dim outlookObj, myNameSpace, myFolder
	Const olFolderInbox = 6			' From Outlook 2000 VB docs

	Set fso = CreateObject("Scripting.FileSystemObject")
	If (fso.FileExists(kSavedOutlookFile)) Then
		On Error Resume Next
		fso.DeleteFile(kSavedOutlookFile)		
		Set outlookObj = CreateObject("Outlook.Application")
		Set myNameSpace = outlookObj.GetNameSpace("MAPI")
		Set myFolder= myNameSpace.GetDefaultFolder(olFolderInbox)
		If (outlookObj.Explorers.Count = 0) Then myFolder.Display
		On Error GoTo 0
	End If
End Sub


'
' QuitOutlook
'	  Quit all instances of Microsoft Outlook
'
Sub QuitOutlook()
	Dim outlookObj, outlookAppNum

	On Error Resume Next
	Set outlookObj = CreateObject("Outlook.Application")
	If (outlookObj.Explorers.Count >= 1) Then
		If (kRelaunchOutlook = True) Then SaveOutlookState
		For outlookAppNum = outlookObj.Explorers.Count To 1 Step -1
			outlookObj.Explorers.Item(outlookAppNum).Application.Quit
		Next
	End If
	On Error GoTo 0
End Sub


'
' StartSource
'     Quit all instances of Outlook 2000 before Retrospect does its backup.
'
Function StartSource(scriptName, sourceName, sourcePath, clientName)
	If (kBackupScripts = "" or InStr(kBackupScripts, scriptName) <> 0) Then
		QuitOutlook
	End If
	StartSource = False
End Function


'
' EndSource
'     Restart Outlook if it was open before the backup
' This will be triggered after any script named "Backup Outlook" runs.
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

	If (kBackupScripts = "" or InStr(kBackupScripts, scriptName) <> 0) Then
		If (kRelaunchOutlook = True) Then OpenSavedOutlook
	End If
End Sub


'
' HandleEvent
'     Dispatch event to each possible function above.
'

Sub HandleEvent()
	Dim cmdArgs
	Dim eventMsg
	Dim argNo
	Dim result
	Dim debugArgs
	Dim WshShell

	Set WshShell = WScript.CreateObject("WScript.Shell")
	Set cmdArgs = WScript.Arguments
	
	If (cmdArgs.Count < 1) Then
		WshShell.Popup "This Retrospect external script will quit any instances of Microsoft Outlook 2000" & _
		vbCrLf & "before proceeding with a scripted backup when a Retrospect script named " & "'Backup Outlook'" & " runs." & _
		vbCrLf & _
		vbCrLf & "To use this file on the backup computer, move it to Retrospect's directory." & _
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
	WshShell.Popup debugArgs								' Uncomment for debugging
	
	' Handle event
	result = False
	Select Case eventMsg
		Case "StartApp"
			'StartApp cmdArgs(1), cmdArgs(2) = "true"
		Case "EndApp"
			'EndApp DateValue(cmdArgs(1))
		Case "StartBackupServer"
			'result = StartBackupServer(cmdArgs(1))
		Case "StopBackupServer"
			'StopBackupServer DateValue(cmdArgs(1))
		Case "StartScript"
			'result = StartScript(cmdArgs(1), DateValue(cmdArgs(2)))
		Case "EndScript"
			'EndScript cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4)
		Case "StartSource"
			result = StartSource(cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4))
		Case "EndSource"
			EndSource cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5), cmdArgs(6), _
				cmdArgs(7), cmdArgs(8), cmdArgs(9), cmdArgs(10), cmdArgs(11), _
				cmdArgs(12), cmdArgs(13), cmdArgs(14), cmdArgs(15), cmdArgs(16)
		Case "MediaRequest"
			'result = MediaRequest(cmdArgs(1), cmdArgs(2), cmdArgs(3) = "true", cmdArgs(4))
		Case "TimedOutMediaRequest"
			'result = TimedOutMediaRequest(cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4))
		Case "ScriptCheckFailed"
			'ScriptCheckFailed cmdArgs(1), DateValue(cmdArgs(2)), cmdArgs(3), cmdArgs(4)
		Case "NextExec"
			'NextExec cmdArgs(1), cmdArgs(2)
		Case "StopSched"
			'result = StopSched(cmdArgs(1), cmdArgs(2))
		Case "PasswordEntry"
			'PasswordEntry cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4)
		Case "FatalBackupError"
			'FatalBackupError cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5), cmdArgs(6)
		Case Else
			'Handle unknown eventMsg
	End Select

	If (result = True) Then
		WScript.Quit(-1)
	Else
		WScript.Quit(0)
	End If
End Sub