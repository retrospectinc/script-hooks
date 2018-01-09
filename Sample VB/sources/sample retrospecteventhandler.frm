VERSION 5.00
Begin VB.Form frmRetroEventHandler 
   Caption         =   "Retrospect Event Handler"
   ClientHeight    =   4185
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4605
   LinkTopic       =   "Form1"
   ScaleHeight     =   4185
   ScaleWidth      =   4605
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdContinue 
      Caption         =   "Continue"
      Default         =   -1  'True
      Height          =   375
      Left            =   1680
      TabIndex        =   1
      Top             =   3720
      Width           =   1215
   End
   Begin VB.Label lblStatus 
      Caption         =   "Sample Caption"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   9.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3495
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   4335
   End
End
Attribute VB_Name = "frmRetroEventHandler"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' sampleRetroEventHandler.frm (frmRetroEventHandler)
'     A simple sample event handler for Retrospect's triggered script mechanism.
'
' (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
'

Option Explicit

Const msgDivider As String = ":" + vbCrLf + vbCrLf


' FormatError
'     Return a string for the passed in error code and error string.
' This is a utility function for the scripts below.
'
Function FormatError(errCode As Integer, errMsg As String) As String
    FormatError = "error #" + FormatNumber(errCode, 0) + " (" + errMsg + ")"
End Function

' FormatSeconds
'     Return a string representing the passed in number of seconds.
' E.g. "2 days 1 minute", "2 hours"
'
Function FormatSeconds(secondsStr)
    Dim secStr
    Dim seconds

    seconds = 1 * secondsStr

    secStr = ""
    If (seconds >= 86400 * 2) Then
        secStr = secStr & (seconds \ 86400) & " days "
        seconds = seconds Mod 86400
    ElseIf (seconds >= 86400) Then
        secStr = secStr & "1 day "
        seconds = seconds Mod 86400
    End If

    If (seconds >= 3600 * 2) Then
        secStr = secStr & (seconds \ 3600) & " hours "
        seconds = seconds Mod 3600
    ElseIf (seconds >= 3600) Then
        secStr = secStr & "1 hour "
        seconds = seconds Mod 3600
    End If

    If (seconds >= 60 * 2) Then
        secStr = secStr & (seconds \ 60) & " minutes "
        seconds = seconds Mod 60
    ElseIf (seconds >= 60) Then
        secStr = secStr & "1 minute "
        seconds = seconds Mod 60
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
    End                                                     ' Quit
End Sub

' StartApp
'     Sent when Retrospect launches. wasAutoLaunched is true if Retrospect was
' launched automatically to run a scheduled script.
'
Sub StartApp(startDate, wasAutoLaunched As Boolean, interventionFile)
    Dim btnClicked As Integer
    Dim msg
    If (wasAutoLaunched) Then
        msg = "StartApp" + msgDivider + _
            "Retrospect is autolaunching on " + startDate + "." + _
            vbCrLf + "Let Retrospect launch?"
    Else
        msg = "StartApp" + msgDivider + _
            "Retrospect is launching on " + startDate + "." + _
            vbCrLf + "Let Retrospect launch?"
    End If
    
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "Retrospect launch stopped by external script.", interventionFile
    End If
End Sub



' EndApp
'     Sent when Retrospect is quitting.
'
Sub EndApp(endDate)
    MsgBox "EndApp" + msgDivider + _
        "Retrospect quit on " + endDate + "."
End Sub

' StartBackupServer
'     Sent when the BackupServer is started via either a script or manually.
' Return true to prevent backup server starting.
'
Sub StartBackupServer(startDate, interventionFile)
    Dim btnClicked As Integer
    Dim msg
    
    msg = "StartBackupServer" & msgDivider & _
        "Retrospect Backup Server is starting on " & _
        startDate & "." & vbCrLf & _
        "Let Backup Server run?"
        
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
         ReturnResult "Backup Server stopped by external script", interventionFile
    End If
End Sub

' StopBackupServer
'     Sent when Backup Server stops.
'
Sub StopBackupServer(endDate)
    MsgBox "StopBackupServer" + msgDivider + _
        "Retrospect Backup Server stopped on " + endDate + "."
End Sub

' StartScript
'     Sent when a script is run, either manually or as part of a scheduled
' execution. Return true to prevent script starting.
'
Sub StartScript(ByVal scriptName As String, startDate, interventionFile)
    Dim btnClicked As Integer
    Dim msg
    
    msg = "StartScript" & msgDivider & _
        "Retrospect script '" & scriptName & "' is starting on " & _
        startDate & "." & vbCrLf & _
        "Let script run?"

    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "Script stopped by external script.", interventionFile
    End If
End Sub

' EndScript
'     Sent when a script finishes.
' numErrors is the total number of errors that occured. fatalErrCode is zero if
' the script was able to complete, otherwise it is a negative number for the
' error that caused the script to abort execution. errMsg is "successful" if
' there was no fatal error, otherwise it is the description of the error.
'
Sub EndScript(ByVal scriptName As String, _
    numErrors As Integer, _
    fatalErrCode As Integer, _
    ByVal errMsg As String)
    Dim msg As String
    
    msg = "EndScript" + msgDivider + "Retrospect script '" + scriptName + "'"
                
    If (fatalErrCode <> 0) Then
        msg = msg + " stopped by " + _
            FormatError(fatalErrCode, errMsg) + "."
    ElseIf (numErrors = 0) Then
        msg = msg + " finished with no errors."
    ElseIf (numErrors = 1) Then
        msg = msg + " finished with one non-fatal error."
    Else
        msg = msg + " with " + FormatNumber(numErrors, 0) + " non-fatal errors."
    End If
   
    MsgBox msg
End Sub

' StartSource
'     Sent immediately before a script backs up a source volume.
' sourceName is the volume name that is being backed up, it will be prefaced
' with "My Computer\" if it is a local volume or the clientName otherwise.
' sourcePath is the file system path of the volume.
'
Sub StartSource( _
    ByVal scriptName As String, _
    ByVal sourceName As String, _
    ByVal sourcePath As String, _
    ByVal clientName As String, _
    interventionFile)
    Dim myComputerName As String
    Dim msg As String
    Dim btnClicked As Integer
    
    myComputerName = "My Computer"
    msg = "StartSource" + msgDivider
    If (Left(clientName, Len(myComputerName)) = myComputerName) Then
        msg = msg + "Script '" + scriptName + "' will back up the local volume '" + _
        sourceName + "' at " + sourcePath + "." + vbCrLf + "Do you want to continue?"
    Else
        msg = msg + "Script '" + scriptName + "' will back up the Client '" + clientName + "'s' volume, '" + sourceName + "' at " + _
            sourcePath + "." + vbCrLf + "Let source start?"
    End If
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "Source skipped by external script", interventionFile
    End If
End Sub

' EndSource
'     Sent after a script has completed backing up a source. As above, sourceName
' is prefaced with either the client name or "My Computer\".
'
Sub EndSource( _
    ByVal scriptName As String, _
    ByVal sourceName As String, _
    ByVal sourcePath As String, _
    ByVal clientName As String, _
    KBBackedUp As Long, _
    numFiles As Long, _
    durationInSecs As Long, _
    backupStartDate, _
    backupStopDate, _
    scriptStartDate, _
    ByVal backupSet As String, _
    ByVal backupAction As String, _
    ByVal parentVolume As String, _
    numErrors As Integer, _
    fatalErrCode As Integer, _
    ByVal errMsg As String)
    Dim myComputerName As String
    Dim msg As String
    
    myComputerName = "My Computer"
    msg = "EndSource" + msgDivider
    
    ' Volume/Client
    If (Left(clientName, Len(myComputerName)) = myComputerName) Then
        msg = msg + "The local volume '" + sourceName + "' at " + sourcePath
    Else
        msg = msg + "Client '" + clientName + "'s' volume, '" + sourceName + _
            "' at " + sourcePath
    End If
    
    ' Errors
  
    If (fatalErrCode <> 0) Then
        msg = msg + " stopped by " + FormatError(fatalErrCode, errMsg) + "."
    ElseIf (numErrors = 0) Then
        msg = msg + " completed successfully."
    ElseIf (numErrors = 1) Then
        msg = msg + " completed with one non-fatal error."
    Else
        msg = msg + " completed with " + FormatNumber(numErrors, 0) + " non-fatal errors."
    End If
    
    msg = msg + vbCrLf + "Script '" + scriptName + "' finished a " + backupAction + _
        " backup to '" + backupSet + "'. " + FormatNumber(numFiles, 0) + _
        " files (" + FormatNumber(KBBackedUp, 0) + "KB) were backed up in " + _
        FormatSeconds(durationInSecs) + "." + vbCrLf
    msg = msg + "The script started on " + scriptStartDate + _
        " and the backup started on " + backupStartDate + _
        " and finished on " + backupStopDate + "."
    MsgBox msg
End Sub

' MediaRequest
'     Sent before Retrospect requests media needed for a backup.
' Return true to fail media request
'

Sub MediaRequest(ByVal mediaLabel As String, _
    ByVal mediaName As String, _
    mediaIsKnown As Boolean, _
    secondsWaited As Integer, _
    interventionFile)
    Dim msg As String
    Dim btnClicked As Integer
    
    msg = "MediaRequest" + msgDivider + _
        "Retrospect is requesting media '" + mediaName + "' (" + mediaLabel + ")"
    If (mediaIsKnown) Then
        msg = msg + vbCrLf + "Retrospect has backed up to this media before."
    Else
        msg = msg + vbCrLf + "This is either a new or unknown media."
    End If
    msg = msg + vbCrLf + "Retrospect has waited " + FormatSeconds(secondsWaited * 60) + " so far." + _
            vbCrLf + "Continue with media request?"
    
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "Media request stopped by external script", interventionFile
    End If
End Sub


' TimedOutMediaRequest
'     Sent before Retrospect times out on waiting for a media request. Note that
' the "Media Request Timeout" option in the preferences must be turned on to
' receive this event.
'
' Return true to reset timeout request.
'
Sub TimedOutMediaRequest(ByVal mediaLabel As String, _
    ByVal mediaName As String, _
    mediaIsKnown As Boolean, _
    secondsWaited As Integer, _
    interventionFile)
    Dim msg As String
    Dim btnClicked As Integer
    
    msg = "TimedOutMediaRequest" + msgDivider + _
        "Retrospect's media request for '" + mediaName + "' (" + mediaLabel + _
        ") is about to time out after waiting " + FormatSeconds(secondsWaited * 60) + "." + _
        vbCrLf + "Let Retrospect time out?"
    
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "TimeOutMediaRequest stopped by external script", interventionFile
    End If
End Sub

' ScriptCheckFailed
'     Sent before Retrospect quits when the next script to execute will not be
' able to run. "Check validity of next script" must be checked in Retrospect's
' preferences (Notification:Alerts) to receive this event.
'
Sub ScriptCheckFailed( _
    ByVal scriptName As String, _
    nextDate, _
    reason, _
    errCode As Integer, _
    ByVal errMsg As String)
    Dim msg
    
    msg = "ScriptCheckFailed" + msgDivider + _
        "The Retrospect script '" + scriptName + "' scheduled on " + nextDate + " will not execute" + _
        " as scheduled due to " + _
        FormatError(errCode, errMsg) + "." + vbCrLf + _
        "Retrospect's dialog: " + reason
        
    MsgBox msg
End Sub

' NextExec
'     Sent before Retrospect quits when the next script to execute is able to
' run. "Check validity of next script" must be checked in Retrospect's
' preferences (Notification:Alerts) to receive this event.
'
Sub NextExec(ByVal scriptName As String, nextDate)
    Dim msg As String
    
    msg = "NextExec" + msgDivider
    msg = msg + "Script '" + scriptName + "' is scheduled to run on " + _
        nextDate + "."
    MsgBox msg
End Sub

' StopSched
'     Sent when an unattended script is scheduled to stop. Return true to keep
' script running.
'
Sub StopSched(ByVal scriptName As String, schedStopDate, interventionFile)
    Dim msg As String
    Dim btnClicked As Integer
    
    msg = "StopSched" + msgDivider
    msg = msg + "Script '" + scriptName + "' is scheduled to stop on " + _
        schedStopDate + "." + vbCrLf + "Let the script stop?"
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "Script was not stopped due to intervention by external script.", interventionFile
    End If
End Sub

' PasswordEntry
'     Sent when a password is entered.
'
Sub PasswordEntry( _
    ByVal actionString As String, _
    attempts As Integer, _
    errCode As Integer, _
    ByVal errMsg As String)
    Dim msg As String
    
    msg = "PasswordEntry" + msgDivider
    If (errCode <> 0) Then
        msg = msg + "Login failed after " + FormatNumber(attempts, 0) + _
                " attempts, " + FormatError(errCode, errMsg) + _
                vbCrLf + "Retrospect's dialog: " + actionString + ""
    ElseIf (attempts = 1) Then
        msg = msg + "Login successful." + vbCrLf + "Retrospect's dialog: " + _
                actionString + ""
    Else
        msg = "Login successful after " + FormatNumber(attempts, 0) + " attempts." + _
                vbCrLf + "Retrospect's dialog: " + actionString + ""
    End If
    MsgBox msg
End Sub

' FatalBackupError
'     Sent when a unrecoverable error is detected, such as a hardware
' failure.
'
Function FatalBackupError( _
    scriptName, _
    reason, _
    errCode As Integer, _
    ByVal errMsg As String, _
    errZone, _
    interventionFile)
    
    Dim msg As String
    Dim btnClicked As Integer
    
    msg = "Script '" + scriptName + "' failed in " + errZone + " " + _
            FormatError(errCode, errMsg) + "." + vbCrLf + reason + "." + _
            vbCrLf + "Retrospect's dialog: '" + reason + "'" + vbCrLf + _
            "Do you want to display a modal dialog?"
    btnClicked = MsgBox(msg, vbOKCancel)
    If (btnClicked <> 1) Then
        ReturnResult "External script prevented the display of a modal dialog.", interventionFile
    End If
End Function
    
' Form_Load
'     A sample event handler.
'
Private Sub Form_Load()
    Dim cmdArgs
    Dim eventMsg As String
    Dim statusMsg As String
    Dim argNo As Integer
    Dim waitForUser As Boolean
    
    lblStatus = "Started"
    cmdArgs = getCmdArgs()
    If (UBound(cmdArgs) < 1) Then
        MsgBox "This is a sample Retrospect external script written in Visual Basic." & _
        vbCrLf & _
        vbCrLf & "To use this file on the backup server, move it to Retrospect's directory." & _
        vbCrLf & "To use this file on a client machine, copy it to the directory containing" & _
        vbCrLf & "the Retrospect client ('retroclient.exe')."
    
        End
    End If
    
    ' get args for debugging
    statusMsg = "Arguments:"
    statusMsg = statusMsg + vbCrLf + Command() + vbCrLf
    For argNo = LBound(cmdArgs) To UBound(cmdArgs)
        statusMsg = statusMsg + vbCrLf + FormatNumber(argNo, 0) + ":" + cmdArgs(argNo)
    Next argNo
    lblStatus = statusMsg
    
    'MsgBox statusMsg                                       ' Uncomment to debug arguments
    
    ' Handle event
    waitForUser = False
    eventMsg = cmdArgs(0)
    Select Case eventMsg
        Case "StartApp"
            StartApp cmdArgs(1), (cmdArgs(2) = "true"), cmdArgs(3)
        Case "EndApp"
            EndApp cmdArgs(1)
        Case "StartBackupServer"
            StartBackupServer cmdArgs(1), cmdArgs(2)
        Case "StopBackupServer"
            StopBackupServer cmdArgs(1)
        Case "StartScript"
            StartScript cmdArgs(1), cmdArgs(2), cmdArgs(3)
        Case "EndScript"
            EndScript cmdArgs(1), Val(cmdArgs(2)), Val(cmdArgs(3)), cmdArgs(4)
        Case "StartSource"
            StartSource cmdArgs(1), cmdArgs(2), cmdArgs(3), cmdArgs(4), cmdArgs(5)
        Case "EndSource"
            EndSource cmdArgs(1), cmdArgs(2), cmdArgs(3), (cmdArgs(4)), Val(cmdArgs(5)), Val(cmdArgs(6)), _
                Val(cmdArgs(7)), cmdArgs(8), cmdArgs(9), cmdArgs(10), _
                cmdArgs(11), cmdArgs(12), cmdArgs(13), Val(cmdArgs(14)), _
                Val(cmdArgs(15)), cmdArgs(16)
        Case "MediaRequest"
            MediaRequest cmdArgs(1), cmdArgs(2), cmdArgs(3) = "true", Val(cmdArgs(4)), cmdArgs(5)
        Case "TimedOutMediaRequest"
            TimedOutMediaRequest cmdArgs(1), cmdArgs(2), cmdArgs(3) = "true", Val(cmdArgs(4)), cmdArgs(5)
        Case "ScriptCheckFailed"
            ScriptCheckFailed cmdArgs(1), cmdArgs(2), cmdArgs(3), Val(cmdArgs(4)), cmdArgs(5)
        Case "NextExec"
            NextExec cmdArgs(1), cmdArgs(2)
        Case "StopSched"
            StopSched cmdArgs(1), cmdArgs(2), cmdArgs(3)
        Case "PasswordEntry"
            PasswordEntry cmdArgs(1), Val(cmdArgs(2)), Val(cmdArgs(3)), cmdArgs(4)
        Case "FatalBackupError"
            FatalBackupError cmdArgs(1), cmdArgs(2), Val(cmdArgs(3)), cmdArgs(4), cmdArgs(5), cmdArgs(6)
        Case Else
            MsgBox "Unknown command: " + eventMsg
            waitForUser = True
   End Select
   If (waitForUser = False) Then End
End Sub

' cmdContinue_Click
'     Quit the application and return to Retrospect.
' Retrospect will continue to wait until the application closes.
'
Private Sub cmdContinue_Click()
    End
End Sub

' getCmdArgs
'     Return an array of strings, one for each command argument.
' This function can handle command line arguments delimited by either spaces or
' quotes. It cannot distinguish between embedded quotes (use single quotes (')).
' The quotes are removed before being added to the array.
'
Function getCmdArgs() As Variant
    Dim cmdArgs()
    Dim cmdLine As String
    Dim cmdLen As Integer
    Dim numArgs As Integer
    Dim delim As String
    Dim c As Integer
    Dim nextChar As String
    Dim inArgs As Boolean
    Dim anArg As String
    
    cmdLine = Command()
    cmdLen = Len(cmdLine)
    
    If (cmdLen = 0) Then
        getCmdArgs = Array()                                ' Empty array
        Exit Function
    End If
    
    inArgs = False
    delim = ""
    For c = 1 To cmdLen
        nextChar = Mid(cmdLine, c, 1)
        
        ' skip spaces, if we see a quote, start the arg on the next char
        If (Not inArgs) Then
            If (delim = "" And nextChar = """") Then
                delim = nextChar
            ElseIf (delim = """" Or nextChar <> " ") Then
                If (delim = "") Then delim = " "
                inArgs = True
                anArg = ""
            End If
        End If
        
        If (inArgs) Then
            If (nextChar = delim) Then
                ReDim Preserve cmdArgs(numArgs)
                cmdArgs(numArgs) = anArg
                numArgs = numArgs + 1
                anArg = ""
                delim = ""
                inArgs = False
            Else
                anArg = anArg & nextChar
            End If
        End If
    Next c
    getCmdArgs = cmdArgs()
End Function
