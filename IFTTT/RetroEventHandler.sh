#!/bin/sh

# Sample Retrospect Event Handler for integration with IFTTT
# 
#     The Retrospect application will call this  file with the first
# argument as the subroutine name (e.g. "EndSource").
#     Events supported by Retrospect (See the methods below for the 
# arguments passed in for each event.)
# StartApp -- Retrospect has been launched
# EndApp -- Retrospect is quitting
# StartBackupServer - The backup server is starting
# StopBackupServer - The backup server is stopping
# StartScript - A script is beginning
# EndScript - A script is stopping
# StartSource - A volume is about to be backed up
# EndSource - A volume has been backed up
# 
# MediaRequest - Retrospect needs media.
# TimedOutMediaRequest - If "Media Request Times Out" is set in "Special-Preferences"
#     then this message is sent before timing out. Return an error to cause
#     Retrospect to reset its timer.
# 
# ScriptCheckFailed - Called before Retrospect quits if the next scheduled
#     script will not be able to run (due to no media or other conditions).
# NextExec - Called before Retrospect quits with the name and start date of
#     the next script that will be able to run.
# 
# StopSched - Called when a script has a scheduled interval to run before the
#     interval has elapsed. Return an error to cause Retrospect to continue
#     executing the script.
# 
# PasswordEntry - Called whenever a password is entered.
# FatalBackupError - Called whenever an un-recoverable error occurs. (i.e hardware 
# 	failure)
# 
# (C) Retrospect, Inc.
# 

# To integrate Retrospect with IFTTT, you need:
# - An account on IFTTT
# - Create a Maker account (c.f. https://ifttt.com/maker)
# - Create an IFTTT Maker trigger (https://internal-api.ifttt.com/maker)
# - Paste in the key from your Maker account in place of the "xxxxxxxxxxxxxxxxx" below
# If you want to customize each event, you can create a trigger for each, making the eventName correspond to the Retrospect event.
# If you want to use one trigger for all events, fill that in below. For this example, we use a single 'retrospect_event' trigger name.
makerKey="xxxxxxxxxxxxxxxxx" # Fill in with your Maker key (listed at https://internal-api.ifttt.com/maker)
triggerName="retrospect_event" # Fill in to send to a single trigger name, leave empty to use name of event (e.g. EndSource)

# To test this script, run the following in the terminal:
# > cd "/Library/Application Support/Retrospect/"
# > retroEventHandler.sh StartApp "2/10/2016 12:01 AM" "true"

function sendToIFTTT {
    eventName=$1 ; shift
    title=$1 ; shift
    text=$1 ; shift
    color=$1 ; shift
    fields=$1 ; shift

    triggerEvent=eventName
    if [ "$triggerName" != "" ] ; then
        triggerEvent="$triggerName"
    fi

    curl -G -v "https://maker.ifttt.com/trigger/$triggerEvent/with/key/$makerKey" --data-urlencode "value1=$title" --data-urlencode "value2=$text" --data-urlencode "value3=$eventName"
}

function abort_with_msg {
    interventionFile=$1
    msg=$2
    echo $msg > $interventionFile
    exit 1
}

function StartApp {
    eventDate=$1                # e.g. 2/10/2017 15:39
    autoLaunched=$2             # Always true for Mac engine
    interventionFile=$3         # Anything written to this file will be written to the log and cause Retrospect to cancel
    sendToIFTTT "StartApp" "Retrospect launched" "Starting Retrospect on $eventDate"
  
    # To cancel Retrospect event
    # abort_with_msg $interventionFile "Launch cancelled by RetroEventHandler"
}

function EndApp {
    eventDate=$1                # e.g. 2/10/2017 15:39
    sendToIFTTT "EndApp" "Retrospect quit" "Quitting Retrospect on $eventDate"
}

function StartBackupServer {
    eventDate=$1 ; shift         # e.g. 2/10/2017 15:39
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to cancel
    sendToIFTTT "StartBackupServer" "Proactive Backup Server" "Proactive started on $eventDate"

    # To cancel Retrospect event
    # abort_with_msg interventionFile "Proactive backup cancelled by RetroEventHandler.rb"
}

function StopBackupServer {
    eventDate=$1 ; shift         # e.g. 2/10/2017 15:39
    sendToIFTTT "StopBackupServer" "Proactive Backup Server" "Proactive stopped on $eventDate"
}

function StartScript {
    scriptName=$1 ; shift
    eventDate=$1 ; shift         # e.g. 2/10/2017 15:39
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to cancel
    sendToIFTTT "StartScript" "Script $scriptName started" "Retrospect script $scriptName started on $eventDate"

    # To cancel Retrospect event
    # abort_with_msg interventionFile "Script $scriptName cancelled by RetroEventHandler.rb"
}

function EndScript {
    scriptName=$1 ; shift
    numErrors=$1 ; shift
    fatalErrCode=$1 ; shift
    fatalErrMsg=$1 ; shift
    if [ $((fatalErrCode)) -ne 0 ] ; then
        sendToIFTTT "EndScript" "Script $scriptName finished" "Retrospect script $scriptName stopped with error $fatalErrCode - $fatalErrMsg."
    elif [ $((numErrors)) -ne 0 ] ; then
        fields=""
        sendToIFTTT "EndScript" "Script $scriptName finished"  "Retrospect script $scriptName finished with $numErrors errors."
    else
        fields=""
        sendToIFTTT "EndScript" "Script $scriptName finished"  "Retrospect script $scriptName finished successfully."
    fi
}

function StartSource {
    scriptName=$1 ; shift
    volName=$1 ; shift
    sourcePath=$1 ; shift
    clientName=$1 ; shift
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to cancel
    sendToIFTTT "StartSource" "Source $volName started" "Retrospect script $scriptName started backing up volume $volName."

    # To cancel Retrospect event
    # abort_with_msg interventionFile "Backup of source $volName cancelled by RetroEventHandler.rb"
}

function EndSource {
    scriptName=$1 ; shift
    sourceName=$1 ; shift
    sourcePath=$1 ; shift
    clientName=$1 ; shift
    kbBackedUp=$1 ; shift
    numFiles=$1 ; shift
    duration=$1 ; shift
    sourceStart=$1 ; shift
    sourceEnd=$1 ; shift
    scriptStart=$1 ; shift
    backupSet=$1 ; shift
    backupAction=$1 ; shift
    parentVol=$1 ; shift
    numErrors=$1 ; shift
    fatalErrCode=$1 ; shift
    fatalErrMsg=$1 ; shift

    title="Source $sourceName finished"
    
    if [ $((fatalErrCode)) -ne 0 ] ; then
        sendToIFTTT "EndSource" "$title" "Script $scriptName, backing up $sourceName, was stopped with error $fatalErrCode - $fatalErrMsg."
    elif [ $((numErrors)) -ne 0 ] ; then
        sendToIFTTT "EndSource" "$title" "Script $scriptName, backed up $sourceName with $numErrors errors."
    else
        sendToIFTTT "EndSource" "$title" "Script $scriptName, backed up $sourceName successfully."
    fi
}

# Media Request and other housekeeping events

function MediaRequest {
    backupSet=$1 ; shift
    memberName=$1 ; shift
    mediaIsKnown=$1 ; shift
    waited=$1 ; shift
    interventionFile=$1 ; shift

    sendToIFTTT "MediaRequest" "Media Request" "Retrospect is requesting media $memberName from $backupSet."

    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Media Request for $mediaName cancelled by RetroEventHandler.rb"
}

function TimedOutMediaRequest {
    backupSet=$1 ; shift
    memberName=$1 ; shift
    mediaIsKnown=$1 ; shift
    waited=$1 ; shift
    interventionFile=$1 ; shift
    sendToIFTTT "TimedOutMediaRequest" "Media Request time out" "Retrospect's request for media $memberName from $backupSet is about to time out after waiting $waited minutes."

    # In this case, cancelling means, reset the media request to try again
    # abort_with_msg interventionFile, "Media Request timeout for $mediaName was cancelled by RetroEventHandler.rb"
}

function ScriptCheckFailed {
    scriptName=$1 ; shift
    startDate=$1 ; shift
    reason=$1 ; shift
    errCode=$1 ; shift
    errMsg=$1 ; shift

    sendToIFTTT "ScriptCheckFailed" "Script $scriptName not ready" "Script $scriptName will not run on $startDate: $reason ($errCode - $errMsg)"
}

function NextExec {
    scriptName=$1 ; shift
    startDate=$1 ; shift

    sendToIFTTT "NextExec" "Script $scriptName next to run" "Script $scriptName is ready to run on $startDate."
}

function StopSched {
    # A script is hitting its scheduled stop time
    scriptName=$1 ; shift
    startDate=$1 ; shift
    interventionFile=$1 ; shift

    sendToIFTTT "StopSched" "Script $scriptName stopping before finished" "Script $scriptName is scheduled to stop on $startDate."

    # In this case, cancelling means, letting the script continue
    # abort_with_msg interventionFile, "Script $scriptName was told to continue to run by RetroEventHandler.rb"
}

function PasswordEntry {
    # Someone tried to log into Retrospect, a client, backup set or other object
    objectStr=$1 ; shift
    attempts=$1 ; shift
    errCode=$1 ; shift
    errMsg=$1 ; shift
    
    if [ "$errMsg" == "successful" ] ; then
        if [ $((attempts)) -gt 0 ] ; then
            sendToIFTTT "PasswordEntry" "Retrospect login successful" "Login to $objectStr successful after $attempts attempts."
        else
            sendToIFTTT "PasswordEntry" "Retrospect login successful"  "Login to $objectStr successful"
        fi
    else
  	    sendToIFTTT "PasswordEntry" "Retrospect login failed!"  "Login to $objectStr failed after $attempts attempts (error # $errCode - $errMsg)"
    fi
}

function FatalBackupError {
    # A script had a serious error while backing up. This happens before EndScript.
    scriptName=$1 ; shift
    failureCause=$1 ; shift
    errCode=$1 ; shift
    errMsg=$1 ; shift
    errZone=$1 ; shift
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to continue script execution

    sendToIFTTT "FatalBackupError" "Fatal Error" "ScriptName $scriptName failed with error #$errCode - $errMsg ($failureCause)"
}


event=$1 ; shift
case $event in
StartApp)
    StartApp "$1" "$2" "$3"
    ;;
EndApp)
    EndApp "$1"
    ;;
StartBackupServer)
    StartBackupServer "$1" "$2"
    ;;
StopBackupServer)
    StopBackupServer "$1"
    ;;
StartScript)
    StartScript "$1" "$2" "$3"
    ;;
EndScript)
    EndScript "$1" "$2" "$3" "$4"
    ;;
StartSource)
    StartSource "$1" "$2" "$3" "$4" "$5"
    ;;
EndSource)
    EndSource "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}" "${16}"
    ;;
MediaRequest)
    MediaRequest "$1" "$2" "$3" "$4" "$5"
    ;;
TimedOutMediaRequest)
    TimedOutMediaRequest "$1" "$2" "$3" "$4" "$5"
    ;;
ScriptCheckFailed)
    ScriptCheckFailed "$1" "$2" "$3" "$4" "$5"
    ;;
NextExec)
    NextExec "$1" "$2"
    ;;
StopSched)
    StopSched "$1" "$2" "$3"
    ;;
PasswordEntry)
    PasswordEntry "$1" "$2" "$3" "$4"
    ;;
FatalBackupError)
    FatalBackupError "$1" "$2" "$3" "$4" "$5" "$6"
    ;;
*)
    echo "This is a sample Retrospect external script written in ruby."
    echo "It will display a message for each Retrospect event."
    echo ""
    echo "To use this file on the backup server, move it to:"
    echo "/Library/Application Support/Retrospect/"
    ;;
esac
