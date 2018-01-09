#!/bin/sh

# Sample Retrospect Event Handler for integration with Slack
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

# To integrate Retrospect with Slack, first create an incoming webhook
# c.f. https://my.slack.com/services/new/incoming-webhook/
slackURL="https://hooks.slack.com/services/Txxxxxxxx/Bxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx"

# To test this script, run the following in the terminal:
# > cd "/Library/Application Support/Retrospect/"
# > retroEventHandler.sh StartApp "2/10/2016 12:01 AM" "true"

function postToSlack {
    title=$1 ; shift
    text=$1 ; shift
    color=$1 ; shift
    fields=$1 ; shift
    
    fallback="$title-$text"
    pretext=""
    fields="[$fields]"

    message="{
        \"username\": \"Retrospect\",
        \"icon_url\": \"http://download.retrospect.com/site/cube_128.png\",
        \"attachments\": [
            {
                \"fallback\": \"$fallback\",
                \"color\": \"$color\",
                \"pretext\": \"$pretext\",
                \"title\": \"$title\",
                \"text\": \"$text\",
                \"fields\": $fields,
                \"footer_icon\": \"http://download.retrospect.com/site/cube_32.png\",
                \"footer\": \"Retrospect, Inc.\",
                \"ts\": `date +%s`
            }
        ]
    }"
    curl -X POST --data-urlencode "payload=$message" $slackURL
    echo
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
    postToSlack "Retrospect launched" "Starting Retrospect on $eventDate"
  
    # To cancel Retrospect event
    # abort_with_msg $interventionFile "Launch cancelled by RetroEventHandler"
}

function EndApp {
    eventDate=$1                # e.g. 2/10/2017 15:39
    postToSlack "Retrospect quit" "Quitting Retrospect on $eventDate"
}

function StartBackupServer {
    eventDate=$1 ; shift         # e.g. 2/10/2017 15:39
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to cancel
    postToSlack "Proactive Backup Server" "Proactive started on $eventDate"

    # To cancel Retrospect event
    # abort_with_msg interventionFile "Proactive backup cancelled by RetroEventHandler.rb"
}

function StopBackupServer {
    eventDate=$1 ; shift         # e.g. 2/10/2017 15:39
    postToSlack "Proactive Backup Server" "Proactive stopped on $eventDate"
}

function StartScript {
    scriptName=$1 ; shift
    eventDate=$1 ; shift         # e.g. 2/10/2017 15:39
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to cancel
    postToSlack "Script $scriptName started" "Retrospect script $scriptName started on $eventDate"

    # To cancel Retrospect event
    # abort_with_msg interventionFile "Script $scriptName cancelled by RetroEventHandler.rb"
}

function EndScript {
    scriptName=$1 ; shift
    numErrors=$1 ; shift
    fatalErrCode=$1 ; shift
    fatalErrMsg=$1 ; shift
    fields="{
            \"title\": \"Errors\",
            \"value\": \"$numErrors\",
            \"short\": true
        },
        {
            \"title\": \"Error Code\",
            \"value\": \"$fatalErrCode\",
            \"short\": true
        },
        {
            \"title\": \"Error Message\",
            \"value\": \"$fatalErrMsg\",
            \"short\": false
        }"
    if [ $((fatalErrCode)) -ne 0 ] ; then
        postToSlack "Script $scriptName finished" "Retrospect script $scriptName stopped with error $fatalErrCode - $fatalErrMsg." "danger" "$fields"
    elif [ $((numErrors)) -ne 0 ] ; then
        fields=""
        postToSlack "Script $scriptName finished"  "Retrospect script $scriptName finished with $numErrors errors." "warning" "$fields"
    else
        fields=""
        postToSlack "Script $scriptName finished"  "Retrospect script $scriptName finished successfully." "good" "$fields"
    fi
}

function StartSource {
    scriptName=$1 ; shift
    volName=$1 ; shift
    sourcePath=$1 ; shift
    clientName=$1 ; shift
    interventionFile=$1 ; shift  # Anything written to this file will be written to the log and cause Retrospect to cancel
    postToSlack "Source $volName started" "Retrospect script $scriptName started backing up volume $volName."

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
    
    error_fields=""
    if [ $((fatalErrCode)) -ne 0 ] ; then
        # Begin with comma to add in error fields at end of stats
        error_fields=",{
            \"title\": \"Errors\",
            \"value\": \"$numErrors\",
            \"short\": true
        },{
            \"title\": \"Error Code\",
            \"value\": \"$fatalErrCode\",
            \"short\": true
        },{
            \"title\": \"Error Message\",
            \"value\": \"$fatalErrMsg\",
            \"short\": false
        }"
    fi
    
    fields="{
        \"title\": \"Destination Set\",
        \"value\": \"$backupSet\",
        \"short\": false
    },{
        \"title\": \"Files\",
        \"value\": \"$numFiles\",
        \"short\": true
    },{
        \"title\": \"KB\",
        \"value\": \"$kbBackedUp\",
        \"short\": true
    }$error_fields"
    
    if [ $((fatalErrCode)) -ne 0 ] ; then
        postToSlack "$title" "Script $scriptName, backing up $sourceName, was stopped with error $fatalErrCode - $fatalErrMsg." "danger" "$fields"
    elif [ $((numErrors)) -ne 0 ] ; then
        postToSlack "$title" "Script $scriptName, backed up $sourceName with $numErrors errors." "warning" "$fields"
    else
        postToSlack "$title" "Script $scriptName, backed up $sourceName successfully." "good" "$fields"
    fi
}

# Media Request and other housekeeping events

function MediaRequest {
    backupSet=$1 ; shift
    memberName=$1 ; shift
    mediaIsKnown=$1 ; shift
    waited=$1 ; shift
    interventionFile=$1 ; shift

    postToSlack "Media Request" "Retrospect is requesting media $memberName from $backupSet." "warning"

    # To cancel Retrospect event
    # abort_with_msg interventionFile, "Media Request for $mediaName cancelled by RetroEventHandler.rb"
}

function TimedOutMediaRequest {
    backupSet=$1 ; shift
    memberName=$1 ; shift
    mediaIsKnown=$1 ; shift
    waited=$1 ; shift
    interventionFile=$1 ; shift
    postToSlack "Media Request time out" "Retrospect's request for media $memberName from $backupSet is about to time out after waiting $waited minutes." "danger"

    # In this case, cancelling means, reset the media request to try again
    # abort_with_msg interventionFile, "Media Request timeout for $mediaName was cancelled by RetroEventHandler.rb"
}

function ScriptCheckFailed {
    scriptName=$1 ; shift
    startDate=$1 ; shift
    reason=$1 ; shift
    errCode=$1 ; shift
    errMsg=$1 ; shift

    postToSlack "Script $scriptName not ready" "Script $scriptName will not run on $startDate: $reason ($errCode - $errMsg)" "warning"
}

function NextExec {
    scriptName=$1 ; shift
    startDate=$1 ; shift

    postToSlack "Script $scriptName next to run" "Script $scriptName is ready to run on $startDate." "good"
}

function StopSched {
    # A script is hitting its scheduled stop time
    scriptName=$1 ; shift
    startDate=$1 ; shift
    interventionFile=$1 ; shift

    postToSlack "Script $scriptName stopping before finished" "Script $scriptName is scheduled to stop on $startDate." "warning"

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
            postToSlack "Retrospect login successful" "Login to $objectStr successful after $attempts attempts." "warning"
        else
            postToSlack "Retrospect login successful"  "Login to $objectStr successful" "green"
        fi
    else
  	    postToSlack "Retrospect login failed!"  "Login to $objectStr failed after $attempts attempts (error # $errCode - $errMsg)" "danger"
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
    fields="{
        \"title\": \"Message\",
        \"value\": \"$failureCause\",
        \"short\": false
    }"
    postToSlack "Fatal Error" "ScriptName $scriptName failed with error #$errCode - $errMsg" "danger" "$fields"
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
