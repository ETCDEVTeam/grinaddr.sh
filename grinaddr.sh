#!/usr/bin/env bash

set -e

HOST=https://send.grinaddr.io
GRIN=grin

COMMAND=$1

GRIN_VERSION=$($GRIN --version)
GA_VERSION=0.2.0
TIMESTAMP=$(date +%Y%m%d%H%M%S)
FILE_PREFIX=grinaddr-$TIMESTAMP

echo "Running grinaddr.sh version $GA_VERSION with grin version $GRIN_VERSION"

if [[ -z "$COMMAND" ]]; then
    COMMAND=start
else
    shift
fi

function failed {
    echo Transfer failed. If current one is not finished, please start a new one
    echo $1
    exit 1
}

function receive {
    TRID=$1

    JOIN_RECEIVER_URL=$HOST/$TRID/join
    JOIN_RETURN_URL=$HOST/$TRID/accept

    echo Waiting for a slate to receive coins...

    RECEIVER_FILE=${FILE_PREFIX}-slate.json
    ACCEPTED_FILE=${RECEIVER_FILE}.response

    curl --silent --fail $JOIN_RECEIVER_URL -d "" -o $RECEIVER_FILE || failed

    echo
    echo Received slate to accept coins, stored as $RECEIVER_FILE
    echo Please sing using Grin wallet:

    $GRIN wallet receive -i $RECEIVER_FILE

    curl --silent --fail -H "Content-Type: application/json" $JOIN_RETURN_URL --data @${ACCEPTED_FILE} || failed

    echo
    echo Slate sent back to sender for finalization
    echo Please verify transaction on blockchain, it make take time while sender will broadcast it to the network
}

function start {
    echo
    echo Receiving GRIN coins through https://grinaddr.io randezvous
    echo

    TRANSFER_FILE=$FILE_PREFIX-id.txt

    curl --silent --fail $HOST/start -o $TRANSFER_FILE || failed

    TRID=$(cat $TRANSFER_FILE)
    JOIN_SEND_URL=$HOST/$TRID

    echo TRANSFER ID $TRID
    echo
    echo Give following URL to sender to send coins to you:
    echo  $JOIN_SEND_URL
    echo

    read -p "Press ENTER after you'll give URL to sender"
    receive $TRID
}

case "$COMMAND" in
    start)
        start
        ;;
    continue)
        TRID=$1
        echo Continue transfer started for $TRID...
        receive $TRID
        ;;
    *)
        echo Receive GRIN coins through https://grinaddr.io randezvous
        echo How to use:
        echo
        echo "    grinaddr.sh - start a new transfer from the beginning"
        echo "    grinaddr.sh continue <TRID> - continue receiving from the last point"
        echo
        echo
        ;;
esac


