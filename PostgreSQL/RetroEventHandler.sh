#!/bin/sh

# Sample Retrospect Event Handler for integration with PostgreSQL
# 
# (C) Retrospect, Inc.
# 

# Note that the PostgreSQL server must have the "wal_level" set to one of the following:
#  wal_level = hot_standby
#  wal_level = archive

# Replace "postgres" with the appropriate user name, if necessary.

function StartSource {
    sudo -u postgres /usr/local/bin/psql -c "select pg_start_backup('retrospect_backup', true);" -q &>/dev/null

    echo
}

function EndSource {
    sudo -u postgres /usr/local/bin/psql -c "select pg_stop_backup();" -q &>/dev/null

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
    echo "It will request a pg_start_backup operation on the PostgreSQL database before"
    echo "backup begins and then pg_stop_backup operation when the backup finishes."
    echo ""
    echo "To use this file on the backup server, move it to:"
    echo "/Library/Application Support/Retrospect/"
    ;;
esac
