# Script Hooks
## External Scripting via Event Handlers

https://www.retrospect.com/support/kb/script_hooks

Retrospect administrators can use Retrospect’s external scripting to hook into Retrospect’s events. These hooks can be used to integrate with monitoring systems, quiesce databases and other services before a backup starts or alert the administrator to unusual error conditions. Script hooks can also be used as web hooks, triggering events on services such as Slack or IFTTT.

Retrospect triggers these events by calling a file named "RetroEventHandler" located in either the application folder (for Windows) or the preferences folder (For Windows, C:\ProgramData\Retrospect. For Mac, /Library/Application Support/Retrospect). This file can be any script type known to the operating system (As examples for Windows, BAT or VBScript. For Mac, bash or ruby). They can even be compiled programs. For each event, Retrospect sends the name of the event followed by information specific for the event.

## Overview
Retrospect administrators can use Retrospect’s external scripting to hook into Retrospect’s events. These hooks can be used to integrate with monitoring systems, quiesce databases and other services before a backup starts or alert the administrator to unusual error conditions. Script hooks can also be used as web hooks, triggering events on services such as Slack or IFTTT.

Retrospect triggers these events by calling a file named "RetroEventHandler". This file can be any script type known to the operating system (As examples for Windows, BAT or VBScript. For Mac, bash or ruby). They can even be compiled programs. For each event, Retrospect sends the name of the event followed by information specific for the event. Retrospect looks in the following locations:

*Retrospect for Windows:* `C:\ProgramData\Retrospect` and `C:\Program Files\Retrospect`

*Retrospect for Mac:* `/Library/Application Support/Retrospect`

*Retrospect Client for Windows:* `C:\Program Files\Retrospect\Retrospect Client`

*Retrospect Client for Mac:* `/Library/Application Support/Retrospect Client/retroeventhandler`

*Retrospect Client for Linux:* `/etc/retroeventhandler`

Note that you do not need to restart the application for Retrospect to recognize the script hooks file. Also note that for Retrospect for Windows, script hooks are only supported for scripted executions, not immediate executions.

## Events

Retrospect has sixteen events that can be handled by scripts. Retrospect client software has two of these events. Below are the event names and descriptions of when they are triggered.

`StartApp` occurs when Retrospect is opening, including when it is autolaunching.

`EndApp` occurs when Retrospect quits.

`StartBackupServer` occurs when Proactive Backup is about to start.

`StopBackupServer` occurs when Proactive Backup is stopped.

`StartScript` occurs when a script is about to start.

`EndScript` occurs when a script is finished.

`AnomalyAlert` occurs when an anomaly has been detected during scan, before the backup begins. See https://www.retrospect.com/en/anomaly_detection for more details.

`StartSource` occurs when a source is about to be accessed for the first time. This event is present in both the Retrospect application and Retrospect client software.

`EndSource` occurs when a source has finished being accessed. This event is present in both the Retrospect application and Retrospect client software.

`MediaRequest` occurs when Retrospect is about to request media, and again every five minutes while the media request window is open.

`TimedOutMediaRequest` occurs when Retrospect has requested media and it has waited longer than the time specified in the preferences.

`ScriptCheckFailed` occurs when Retrospect quits after running a script and there is a scheduled script set to run outside the look ahead time and the script check fails.

`NextExec` occurs when Retrospect quits after running a script and there is a scheduled script set to run outside the look ahead time and the script check passes.

`SchedStop` occurs when a script is running and about to stop because its allowed time of execution has expired.

`PasswordEntry` occurs after someone enters a password.

`FatalBackupError` occurs when a fatal backup error occurs.

For specific information about each event, examine one of the example scripts available on our website and github repository.
