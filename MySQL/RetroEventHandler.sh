#!/bin/sh

# Sample Retrospect Event Handler for integration with MySQL
# 
# (C) Retrospect, Inc.
# 

# Replace "HOSTNAME" with the appropriate hostname.
# Replace "USERNAME" with the appropriate user name.
# Replace "PASSWORD" with the appropriate password.

function StartSource {
    /bin/rm -f /tmp/retrospectmysqlpipe
    /usr/bin/mkfifo /tmp/retrospectmysqlpipe
    # Note that we use 3598 to be a unique number to search for when we kill the sleep during cleanup.
    /bin/sleep 3598 > /tmp/retrospectmysqlpipe &
    /usr/local/bin/mysql -B -h HOSTNAME -u USERNAME -pPASSWORD &>/dev/null < /tmp/retrospectmysqlpipe &
    echo "FLUSH TABLES WITH READ LOCK;" > /tmp/retrospectmysqlpipe

    echo
}

function EndSource {
    /bin/ps -ef | /usr/bin/awk '/[s]leep 3598/{print $2}' | /usr/bin/xargs kill
    /bin/rm -f /tmp/retrospectmysqlpipe

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
    echo "It will lock the MySQL database before"
    echo "backup begins and then unlock when the backup finishes."
    echo ""
    echo "To use this file on the backup server, move it to:"
    echo "/Library/Application Support/Retrospect/"
    ;;
esac
