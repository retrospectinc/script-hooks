/*
 * sample_c.cpp
 *
 *     Sample event handler for Retrospect(R).
 *
 *
 * © 2012 Retrospect, Inc. Portions © 1989-2010 EMC Corporation. All rights reserved.
 *
 */

#include <windows.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "resource.h"

enum eReturnErrors {
	noErr						= 0,
	abortTask					= 1,
};

#define MAX_CHARS				1024						// The maximum length of the error message
#define MAX_ARGS				18							// Maximum number of command line arguments we accept


// globals
char gszTitle[MAX_CHARS];


// prototypes for event handlers
void StartApp(HINSTANCE hInst, PSTR started, PSTR autolaunched, PSTR interventionFile);
void EndApp(HINSTANCE hInst, PSTR stopped);
void StartBackupServer(HINSTANCE hInst, PSTR started, PSTR interventionFile);
void StopBackupServer(HINSTANCE hInst, PSTR stopped);
void StartScript(HINSTANCE hInst, PSTR scriptName, PSTR started, PSTR interventionFile);
void EndScript(HINSTANCE hInst, PSTR scriptName, PSTR numErrors, PSTR fatalErrCode, PSTR fatalErrMsg);
void StartSource(HINSTANCE hInst, PSTR sourceName, PSTR sourcePath, PSTR clientName, PSTR interventionFile);
void EndSource(
	HINSTANCE hInst, 
	PSTR sourceName,
	PSTR sourcePath,
	PSTR KBTrans,
	PSTR filesTrans,
	PSTR duration,
	PSTR scriptStart,
	PSTR sourceStart,
	PSTR sourceEnd,
	PSTR backupSet,
	PSTR clientName,
	PSTR scriptName,
	PSTR action,
	PSTR parentVol,
	PSTR numErrors,
	PSTR fatalErrCode,
	PSTR fatalErrMsg);
void MediaRequest(HINSTANCE hInst, PSTR labelName, PSTR mediaName, PSTR known, PSTR secsWaited, PSTR interventionFile);
void TimedOutMediaRequest(HINSTANCE hInst, PSTR labelName, PSTR mediaName, PSTR secsWaited, PSTR interventionFile);
void PasswordEntry(HINSTANCE hInst, PSTR action, PSTR attempts, PSTR errCode, PSTR errMsg);
void StopSched(HINSTANCE hInst, PSTR scriptName, PSTR stopTime, PSTR interventionFile);
void ScriptCheckFailed(HINSTANCE hInst, PSTR scriptName, PSTR scriptStart, PSTR errCode, PSTR errMsg);
void NextExec(HINSTANCE hInst, PSTR scriptName, PSTR scriptStart, PSTR interventionFile);
void FatalErrorBackup(HINSTANCE hInst, PSTR scriptName, PSTR reason, PSTR errCode, PSTR errMsg, PSTR errZone, PSTR interventionFile);


int getCmdArgs(PSTR szCmdLine, char cmdArgs[MAX_ARGS][MAX_CHARS]);
void formatSeconds(PSTR seconds, PSTR formatedSecs);


// functions

/*
 * ReturnResult
 *
 *		Creates a file that contains the error messages
 *
 */
void
ReturnResult(HINSTANCE hInst, int errmsgid, PSTR interventionFile)
{
	FILE *fp;
	char errMsg[MAX_CHARS];

	if ((fp = fopen(interventionFile, "w")) != NULL)
	{
		LoadString(hInst, errmsgid, errMsg, MAX_CHARS);
		fprintf(fp, errMsg);
		fclose(fp);
	}
	else
	{
		fprintf(stderr, "Can't open file: %s", interventionFile);
		exit(1);
	}
}


/*
 * StartApp
 *
 *     Sent when Retrospect launches. wasAutoLaunched is true if Retrospect was
 * launched automatically to run a scheduled script.
 *
 */

void 
StartApp(HINSTANCE hInst, PSTR started, PSTR autolaunched, PSTR interventionFile)
{
	int result=noErr;

	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	if (strcmp(autolaunched, "true") == 0)
		LoadString(hInst, IDS_AUTOLAUNCHED, resStr, MAX_CHARS);
	else
		LoadString(hInst, IDS_LAUNCHED, resStr, MAX_CHARS);

	sprintf(msg, resStr, started);
	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_STARTAPP, interventionFile);
}


/*
 * EndApp
 *
 *     Sent when Retrospect is quitting.
 *
 */

void EndApp(HINSTANCE hInst, PSTR stopped)
{
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_END_APP, resStr, MAX_CHARS);
	sprintf(msg, resStr, stopped);
	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * StartBackupServer
 *
 *     Sent when the BackupServer is started via either a script or manually.
 * Return true to prevent backup server starting.
 *
 */

void StartBackupServer(HINSTANCE hInst, PSTR started, PSTR interventionFile)
{
	int result = noErr;

	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_START_SERVER, resStr, MAX_CHARS);
	sprintf(msg, resStr, started);
	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_STARTBACKUPSERVER, interventionFile);

}


/*
 * StopBackupServer
 *
 *     Sent when Backup Server stops.
 *
 */

void StopBackupServer(HINSTANCE hInst, PSTR stopped)
{
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_STOP_SERVER, resStr, MAX_CHARS);
	sprintf(msg, resStr, stopped);
	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * StartScript
 *
 *     Sent when a script is run, either manually or as part of a scheduled
 * execution. Return true to prevent script starting.
 *
 */

void StartScript(HINSTANCE hInst, PSTR scriptName, PSTR started, PSTR interventionFile)
{
	int result = noErr;

	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_START_SCRIPT, resStr, MAX_CHARS);
	sprintf(msg, resStr, scriptName, started);
	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_STARTSCRIPT, interventionFile);
}


/*
 * EndScript
 *
 *     Sent when a script finishes.
 * numErrors is the total number of errors that occured. fatalErrCode is zero if
 * the script was able to complete, otherwise it is a negative number for the
 * error that caused the script to abort execution. errMsg is "successful" if
 * there was no fatal error, otherwise it is the description of the error.
 *
 */

void EndScript(HINSTANCE hInst, PSTR scriptName, PSTR numErrors, PSTR fatalErrCode, PSTR fatalErrMsg)
{
	char resStr[MAX_CHARS];
	char errStr[MAX_CHARS];
	char msg[MAX_CHARS];

	if (*fatalErrCode != '0')
		LoadString(hInst, IDS_FATAL_ERROR, resStr, MAX_CHARS);
	else if (*numErrors == '0')
		LoadString(hInst, IDS_SUCCESSFUL, resStr, MAX_CHARS);
	else if (*numErrors == '1' && numErrors[1] == '\0')
		LoadString(hInst, IDS_ONE_ERROR, resStr, MAX_CHARS);
	else
		LoadString(hInst, IDS_MANY_ERRORS, resStr, MAX_CHARS);
	if (*fatalErrCode != '0')
		sprintf(errStr, resStr, fatalErrCode, fatalErrMsg);
	else
		sprintf(errStr, resStr, numErrors);
	LoadString(hInst, IDS_END_SCRIPT, resStr, MAX_CHARS);

	sprintf(msg, resStr, scriptName, errStr);
	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * StartSource
 *
 *     Sent immediately before a script backs up a source volume.
 * sourceName is the volume name that is being backed up, it will be prefaced
 * with "My Computer\" if it is a local volume or the clientName otherwise.
 * sourcePath is the file system path of the volume.
 *
 */

void StartSource(HINSTANCE hInst, PSTR scriptName,PSTR sourceName, PSTR sourcePath, PSTR clientName, PSTR interventionFile)
{
	int result = noErr;

	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_START_SOURCE, resStr, MAX_CHARS);
	sprintf(msg, resStr, scriptName,sourceName, sourcePath, clientName);

	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_STARTSOURCE, interventionFile);

}


/*
 * EndSource
 *
 *     Sent after a script has completed backing up a source. As above, sourceName
 * is prefaced with either the client name or "My Computer\".
 *
 */

void EndSource(
	HINSTANCE hInst, 
	PSTR scriptName,
	PSTR sourceName,
	PSTR sourcePath,
	PSTR clientName,
	PSTR KBTrans,
	PSTR filesTrans,
	PSTR duration,
	PSTR sourceStart,
	PSTR sourceEnd,
	PSTR scriptStart,
	PSTR backupSet,
	PSTR action,
	PSTR parentVol,
	PSTR numErrors,
	PSTR fatalErrCode,
	PSTR fatalErrMsg)
{
	char resStr[MAX_CHARS];
	char errStr[MAX_CHARS];
	char msg[MAX_CHARS];
	char durStr[MAX_CHARS];
	double trans;

	if (*fatalErrCode != '0')
		LoadString(hInst, IDS_FATAL_ERROR, resStr, MAX_CHARS);
	else if (*numErrors == '0')
		LoadString(hInst, IDS_SUCCESSFUL, resStr, MAX_CHARS);
	else if (*numErrors == '1' && numErrors[1] == '\0')
		LoadString(hInst, IDS_ONE_ERROR, resStr, MAX_CHARS);
	else
		LoadString(hInst, IDS_MANY_ERRORS, resStr, MAX_CHARS);
	if (*fatalErrCode != '0')
		sprintf(errStr, resStr,fatalErrCode, fatalErrMsg);
	else
		sprintf(errStr, resStr, numErrors);

	LoadString(hInst, IDS_END_SOURCE, resStr, MAX_CHARS);
	formatSeconds(duration, durStr);

	trans = atof(KBTrans);
	if (trans > 1024 * 1024)
		sprintf(KBTrans, "%.2fGB", trans / (1024 * 1024));
	else if (trans > 1024)
		sprintf(KBTrans, "%.2fMB", trans / 1024);
	else
		sprintf(KBTrans, "%.0fKB", trans);

	sprintf(msg, resStr, 
		sourceName,
		sourcePath,
		clientName,
		errStr,
		scriptName,
		action,
		backupSet,
		filesTrans,
		KBTrans,
		durStr,
		scriptStart,
		sourceStart,
		sourceEnd);
		// don't use parentVol

	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * MediaRequest
 *
 *     Sent before Retrospect requests media needed for a backup.
 *
 *     Return true to fail media request.
 */

void MediaRequest(HINSTANCE hInst, PSTR labelName, PSTR mediaName, PSTR known, PSTR minsWaited, PSTR interventionFile)
{
	int result = noErr;
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];
	char knownStr[MAX_CHARS];
	char waitedStr[MAX_CHARS];
	char secsWaited[MAX_CHARS];
	int mins;
	
	if (*known == 't')
		LoadString(hInst, IDS_MEDIA_KNOWN, knownStr, MAX_CHARS);
	else
		LoadString(hInst, IDS_MEDIA_UNKNOWN, knownStr, MAX_CHARS);

	
	mins=atol(minsWaited);
	sprintf(secsWaited, "%d", mins * 60);
	formatSeconds(secsWaited, waitedStr);
	LoadString(hInst, IDS_MEDIA_REQUEST, resStr, MAX_CHARS);
	sprintf(msg, resStr, mediaName, labelName, knownStr, waitedStr);

	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_MEDIAREQUEST, interventionFile);
}


/*
 * TimedOutMediaRequest
 *
 *     Sent before Retrospect times out on waiting for a media request. Note that
 * the "Media Request Timeout" option in the preferences must be turned on to
 * receive this event.
 *
 *     Return true to reset timeout request.
 *
 */

void TimedOutMediaRequest(HINSTANCE hInst, PSTR labelName, PSTR mediaName, PSTR known, PSTR minsWaited, PSTR interventionFile)
{
	int result = noErr;
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];
	char waitedStr[MAX_CHARS];
	char secsWaited[MAX_CHARS];
	int mins;

	mins = atol(minsWaited);
	sprintf(secsWaited, "%d", mins * 60);
	formatSeconds(secsWaited, waitedStr);
	LoadString(hInst, IDS_TO_MEDIA_REQUEST, resStr, MAX_CHARS);
	sprintf(msg, resStr, mediaName, labelName, waitedStr);

	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_TIMEOUTMEDIAREQUEST, interventionFile);

}


/*
 * PasswordEntry
 *
 *     Sent when a password is entered.
 *
 */

void PasswordEntry(HINSTANCE hInst, PSTR action, PSTR attempts, PSTR errCode, PSTR errMsg)
{
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	if (*errCode != '0')
	{	
		LoadString(hInst, IDS_PASSWORD_FAILED, resStr, MAX_CHARS);
		sprintf(msg, resStr, attempts, errCode, errMsg, action);
	}
	else if (attempts[0] == '1' && attempts[1] == '\0')  
	{	
		LoadString(hInst, IDS_PASSWORD_ONE, resStr, MAX_CHARS);
		sprintf(msg, resStr, action);
	}
	else
	{	
		LoadString(hInst, IDS_PASSWORD_MANY, resStr, MAX_CHARS);
		sprintf(msg, resStr, attempts, action);
	}
		
	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * StopSched
 *
 *     Sent when an unattended script is scheduled to stop. Return true to keep
 * script running.
 *
 */

void StopSched(HINSTANCE hInst, PSTR scriptName, PSTR stopTime, PSTR interventionFile)
{
	int result = noErr;
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_STOPSCHED, resStr, MAX_CHARS);
	sprintf(msg, resStr, scriptName, stopTime);

	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_STOPSCHED, interventionFile);

}


/*
 * ScriptCheckFailed
 *
 *     Sent before Retrospect quits when the next script to execute will not be
 * able to run. "Check validity of next script" must be checked in Retrospect's
 * preferences (Notification:Alerts) to receive this event.
 *
 */

void ScriptCheckFailed(HINSTANCE hInst, PSTR scriptName, PSTR scriptStart, PSTR reason, PSTR errCode, PSTR errMsg)
{
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_SCRIPT_CHECK_FAILED, resStr, MAX_CHARS);

	sprintf(msg, resStr, scriptName, scriptStart, errCode, errMsg, reason);

	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * NextExec
 *
 *     Sent before Retrospect quits when the next script to execute is able to
 * run. "Check validity of next script" must be checked in Retrospect's
 * preferences (Notification:Alerts) to receive this event.
 *
 */

void NextExec(HINSTANCE hInst, PSTR scriptName, PSTR scriptStart)
{
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_NEXT_EXEC, resStr, MAX_CHARS);

	sprintf(msg, resStr, scriptName, scriptStart);

	MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OK);
}


/*
 * FatalBackupError
 *
 *     Sent when a unrecoverable error is detected, such as a hardware
 * failure
 *
 */

void FatalBackupError(HINSTANCE hInst, PSTR scriptName, PSTR reason, PSTR errCode, PSTR errMsg, PSTR errZone, PSTR interventionFile)
{
	int result = noErr;
	char resStr[MAX_CHARS];
	char msg[MAX_CHARS];

	LoadString(hInst, IDS_FATALERROR, resStr, MAX_CHARS);
	sprintf(msg, resStr, scriptName, errZone, errCode, errMsg, reason);

	result = MessageBox(NULL, msg, gszTitle, MB_ICONINFORMATION | MB_OKCANCEL);
	if (result != IDOK)
		ReturnResult(hInst, IDS_ABORT_FATALBACKUPERROR, interventionFile);

}


/*
 * WinMain
 *
 *     Dispatch the event specified in the first command line argument to the
 * appropriate function above.
 *
 */

int WINAPI
WinMain(HINSTANCE hInst, HINSTANCE hNotUsed, PSTR szCmdLine, int iCmdShow)
{
	char szMsg[MAX_CHARS];
	char *szTempPtr = szMsg;
	int numArgs;
	char args[MAX_ARGS][MAX_CHARS];
	
	// Form caption (the text of the title bar)
	LoadString(hInst, IDS_APP_TITLE, gszTitle, MAX_CHARS);

	szCmdLine = GetCommandLine();							// get entire command line
	if ((numArgs = getCmdArgs(szCmdLine, args)) < 2)
	{
		LoadString(hInst, IDS_APP_MESSAGE, szMsg, MAX_CHARS);
		MessageBox(NULL, szMsg, gszTitle, MB_ICONINFORMATION | MB_OK);
		return (noErr);										// need <appname> <eventName> at least
	}
	
#ifdef _DEBUG
	// debug arguments
	for (--numArgs; numArgs > 0; --numArgs)
		MessageBox(NULL, args[numArgs], gszTitle, MB_ICONINFORMATION | MB_OK);
#endif

	if (strcmp(args[1], "StartApp") == 0)
		StartApp(hInst, args[2], args[3], args[4]);
	else if (strcmp(args[1], "EndApp") == 0)
		EndApp(hInst, args[2]);
	else if (strcmp(args[1], "StartBackupServer") == 0)
		StartBackupServer(hInst, args[2], args[3]);
	else if (strcmp(args[1], "StopBackupServer") == 0)
		StopBackupServer(hInst, args[2]);
	else if (strcmp(args[1], "StartScript") == 0)
		StartScript(hInst, args[2], args[3], args[4]);
	else if (strcmp(args[1], "EndScript") == 0)
		EndScript(hInst, args[2], args[3], args[4], args[5]);
	else if (strcmp(args[1], "StartSource") == 0)
		StartSource(hInst, args[2], args[3], args[4], args[5], args[6]);
	else if (strcmp(args[1], "EndSource") == 0)
		EndSource(hInst, args[2], args[3], args[4], args[5], args[6], args[7], 
		args[8], args[9], args[10], args[11], args[12], args[13], args[14], 
		args[15], args[16], args[17]);
	else if (strcmp(args[1], "MediaRequest") == 0)
		MediaRequest(hInst, args[2], args[3], args[4], args[5], args[6]);
	else if (strcmp(args[1], "TimedOutMediaRequest") == 0)
		TimedOutMediaRequest(hInst, args[2], args[3], args[4], args[5], args[6]);
	else if (strcmp(args[1], "PasswordEntry") == 0)
		PasswordEntry(hInst, args[2], args[3], args[4], args[5]);
	else if (strcmp(args[1], "StopSched") == 0)
		StopSched(hInst, args[2], args[3], args[4]);
	else if (strcmp(args[1], "ScriptCheckFailed") == 0)
		ScriptCheckFailed(hInst, args[2], args[3], args[4], args[5], args[6]);
	else if (strcmp(args[1], "NextExec") == 0)
		NextExec(hInst, args[2], args[3]);
	else if (strcmp(args[1], "FatalBackupError") == 0)	
		FatalBackupError(hInst, args[2], args[3], args[4], args[5], args[6], args[7]);

	return (0);
}


/*
 * getCmdArgs
 *
 *     Return the space or quote delimited args in cmdArgs.
 * Return the number of arguments parsed. The delimiting quotes, if any, are 
 * stripped off.
 *
 */

int
getCmdArgs(PSTR szCmdLine, char cmdArgs[MAX_ARGS][MAX_CHARS])
{
	int numArgs = 0;
	char delim = 0;
	char next;
	char *argp = 0;

	while ((next = *szCmdLine++) != 0)
	{
		if (argp == 0)
		{
			if (delim == 0 && next == '"')
				delim = next;
			else if (next != ' ' || delim == '"')
			{
				if (delim == 0)
					delim = ' ';
				argp = cmdArgs[numArgs++];
			}
		}
		
		if (argp != 0)
		{
			if (next == delim)								// done with this arg
			{
				*argp = '\0';
				argp = 0;
				delim = 0;
			}
			else
			{
				*argp++ = next;
			}
		}
	}

	if (argp != 0)
		*argp = 0;											// didn't terminate last arg

	return (numArgs);
}

void
formatSeconds(PSTR seconds, PSTR formatedSecs)
{
	long int secs, mins, hrs, days;

	secs = atol(seconds);

	if (secs == 0)
		formatedSecs += sprintf(formatedSecs, "0 seconds ");
	
	days = secs / 86400;
	secs = secs % 86400;

	hrs = secs / 3600;
	secs = secs % 3600;

	mins = secs / 60;
	secs = secs % 60;

	if (days > 0)
	{
		if (days == 1)
			formatedSecs += sprintf(formatedSecs, "1 day ");
		else
			formatedSecs += sprintf(formatedSecs, "%d days ", days);
	}

	if (hrs > 0)
	{
		if (hrs == 1)
			formatedSecs += sprintf(formatedSecs, "1 hour ");
		else
			formatedSecs += sprintf(formatedSecs, "%d hours ", hrs);
	}

	if (mins > 0)
	{
		if (mins == 1)
			formatedSecs += sprintf(formatedSecs, "1 minute ");
		else
			formatedSecs += sprintf(formatedSecs, "%d minutes ", mins);
	}

	if (secs > 0)
	{
		if (secs == 1)
			formatedSecs += sprintf(formatedSecs, "1 second ");
		else
			formatedSecs += sprintf(formatedSecs, "%d seconds ", secs);
	}

	--formatedSecs;											// back up over the terminating space
	*formatedSecs = '\0';
}