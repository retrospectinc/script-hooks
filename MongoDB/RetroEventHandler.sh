#!/bin/sh

# Sample Retrospect Event Handler for integration with MongoDB
# 
# (C) Retrospect, Inc.
# 

# Replace "/usr/local/bin/mongo" with the appropriate path to "mongo".
# Replace "admin" with the appropriate user name.
# Replace "/data/dump" with the appropriate path for the exported data dump file.

function StartSource {
    # Datastore Protection
    /usr/local/bin/mongo admin --eval "printjson(db.fsyncLock())" &>/dev/null
    # Export Protection
    # /usr/local/bin/mongodump -o /data/dump &>/dev/null
    echo
}

function EndSource {
    # Datastore Protection
    /usr/local/bin/mongo admin --eval "printjson(db.fsyncUnlock())" &>/dev/null
    echo
}

event=$1 ; shift
case $event in
StartSource)
    StartSource "$1" "$2" "$3" "$4" "$5"
    ;;
EndSource)
    EndSource "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}" "${16}"
    ;;
*)
    echo "This is a sample Retrospect external script written in Bash."
    echo "It will call the mongo admin to lock the mongo database before"
    echo "backup begins and then unlock when the backup finishes."
    echo ""
    echo "To use this file on the backup server, move it to:"
    echo "/Library/Application Support/Retrospect/"
    ;;
esac
