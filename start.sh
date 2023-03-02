#!/bin/bash

UNB64=$(echo $BASE64_ARGS_VAR | base64 --decode)
WALLET=$(jq -r '.wallet' <<< $UNB64)
WORKER=$(jq -r '.worker_name' <<< $UNB64)

if [[ "$WALLET" == "null" || ( -z "$WALLET") ]];
	then
		echo 'empty wallet supplied'
		exit
	fi

if [[ "$WORKER" == "null" || ( -z "$WORKER") ]];
	then
		WORKER=$TASKNAME
	fi

/lolMiner/lolMiner --algo ETCHASH --pool etc.2miners.com:1010 --user $WALLET --worker $WORKER --apiport 18058
