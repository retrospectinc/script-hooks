VERSION 5.00
Begin VB.Form RetrospectEventHandler 
   Caption         =   "Retrospect Event Handler"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4605
   LinkTopic       =   "Form1"
   ScaleHeight     =   3195
   ScaleWidth      =   4605
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdContinue 
      Caption         =   "Continue"
      Default         =   -1  'True
      Height          =   375
      Left            =   1680
      TabIndex        =   1
      Top             =   2640
      Width           =   1215
   End
   Begin VB.Label lblStatus 
      Caption         =   "Backup Outlook Event Handler"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   9.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2295
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   4215
   End
End
Attribute VB_Name = "RetrospectEventHandler"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' quitOutlookEventHandler.frm (frmRetroEventHandler)
'     Quit Outlook application instances before Retrospect backs them up.
'
' (C) 2012 Retrospect, Inc. Portions (C) 1989-2010 EMC Corporation. All rights reserved.
'

Option Explicit

' Declare external functions
Private Declare Function FindWindow Lib "user32" Alias _
    "FindWindowA" (ByVal lpClassName As String, _
    ByVal lpWindowName As String) As Long
Private Declare Function PostMessage Lib "user32" Alias _
    "PostMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, _
    ByVal wParam As Long, lParam As Any) As Long

' Declare constants
Const WM_CLOSE = &H10

' cmdContinue_Click
'     Quit the application and return to Retrospect.
' Retrospect will continue to wait until the application closes.
'
Private Sub cmdContinue_Click()
    End
End Sub

' StartSource
'     Quit Outlook if source is local volume.
'
'     StartSource is sent before a script backs up a source volume.
' sourceName is the volume name that is being backed up, it will be prefaced
' with "My Computer\" if it is a local volume or the clientName otherwise.
' sourcePath is the file system path of the volume.
'
Function StartSource(ByVal sourceName As String, ByVal sourcePath As String, ByVal clientName As String) As Boolean
    Dim myComputerName As String
    Dim msg As String

    myComputerName = "My Computer"
    If (Left(sourceName, Len(myComputerName)) = myComputerName) Then
        QuitOutlook
    End If
    StartSource = False
End Function

' Form_Load
'
Private Sub Form_Load()
    Dim commandArgs
    Dim eventMsg As String
    Dim result
    
    lblStatus = "Started"
    commandArgs = getCmdArgs()
    If (UBound(commandArgs) = 0) Then
        lblStatus = "No commandArgs"
        Exit Sub
    End If
    
    ' Handle event
    eventMsg = commandArgs(0)
    Select Case eventMsg
        Case "StartSource"
            result = StartSource(commandArgs(1), commandArgs(2), commandArgs(3))
            End
        Case "EndSource"
            End
        Case "StartScript"
            End
        Case "EndScript"
            End
        Case "MediaRequest"
            End
        Case "MediaRequestTimedOut"
            End
        Case "PasswordEntry"
            End
        Case "ScriptCheckFailed"
            End
        Case "BackupServerStart"
            End
        Case "BackupServerStop"
            End
        Case "AppStart"
            End
        Case "AppEnd"
            End
        Case "SchedStop"
            End
        Case "NextExec"
            End
        Case Else
    End Select
End Sub

Private Sub QuitOutlook()
    Dim outlookObj As Object
    Dim outlookAppNum As Integer

    On Error Resume Next
    Set outlookObj = CreateObject("Outlook.Application")
    For outlookAppNum = outlookObj.Explorers.Count - 1 To 0 Step -1
        outlookObj.Explorers.Item(outlookAppNum).Application.Quit
    Next outlookAppNum
    On Error GoTo 0
End Sub


' getCmdArgs
'     Return an array of strings, one for each command argument.
' This function can handle command line arguments delimited by either spaces or
' quotes. It cannot distinguish between embedded quotes (use single quotes (')).
'
Function getCmdArgs()
    Dim cmdLine As String
    Dim cmdLen As Integer
    Dim delim As String
    Dim anArg As String
    Dim argChar As String
    Dim nextChar As String
    Dim cmdArgs()
    Dim numArgs As Integer
    Dim c As Integer
    Dim inArgs As Boolean
    
    Const kQuote = """"
    Const kSpace = " "
    
    cmdLine = Command()
    cmdLen = Len(cmdLine)
    
    If (cmdLen = 0) Then
        getCmdArgs = Array()                                ' Empty array
        Exit Function
    End If
    
    ' if the first letter is a quote, use it as the delimiter, otherwise use white space
    If (Mid(cmdLine, 1, 1) = kQuote) Then
        delim = kQuote
    Else
        delim = " "
    End If
    
    numArgs = 0
    inArgs = (delim = kSpace)
    For c = 1 To cmdLen
        argChar = Mid(cmdLine, c, 1)
        If (delim = kSpace) Then
            If (argChar <> kSpace And argChar <> vbTab) Then
                inArgs = True
                anArg = anArg + argChar
            Else
                If (inArgs) Then
                    ' add arg and clear it
                    ReDim Preserve cmdArgs(numArgs)
                    cmdArgs(numArgs) = anArg
                    anArg = ""
                    numArgs = numArgs + 1
                End If
                inArgs = False
            End If
        Else                                                ' delim is quote
            If (c = cmdLen) Then
                nextChar = " "
            Else
                nextChar = Mid(cmdLine, c + 1, 1)
            End If
            If (inArgs = False And argChar = kQuote) Then
                inArgs = True
            ElseIf (inArgs And (argChar <> kQuote Or nextChar <> kSpace)) Then
                anArg = anArg + argChar
            Else
                If (inArgs) Then
                    ' add arg and clear it
                    ReDim Preserve cmdArgs(numArgs)
                    cmdArgs(numArgs) = anArg
                    anArg = ""
                    numArgs = numArgs + 1
                End If
                inArgs = False
            End If
        End If
    Next c
    
    getCmdArgs = cmdArgs()
End Function

' testReturnError
'
Sub testReturnError()
    Dim msg
    
    On Error Resume Next
    Err.Clear
    Err.Raise 17, "RetrospectEvent Handler", "A description of the error."
    
    MsgBox "We just raised an error!"
    
    If Err.Number <> 0 Then
        msg = "Error # " & Str(Err.Number) & " was generated by " _
              & Err.Source & Chr(13) & Err.Description
        MsgBox msg, , "Error", Err.HelpFile, Err.HelpContext
    End If
End Sub



