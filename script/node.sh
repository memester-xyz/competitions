#!/usr/bin/env bash

if [ -f ".env" ]; then
    eval "$(
      cat .env | awk '!/^\s*#/' | awk '!/^\s*$/' | while IFS='' read -r line; do
        key=$(echo "$line" | cut -d '=' -f 1)
        value=$(echo "$line" | cut -d '=' -f 2-)
        echo "export $key=$value"
      done
    )"
else
    echo No .env file found!
    exit 0
fi

# Kill anvil after we exit this script
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

# Wait for anvil to be listening
exec 3< <(anvil -f $MUMBAI_RPC_URL -b 5 "$@")
sed '/Listening/q' <&3 ; cat <&3 &

# Wait for exit command CTRL+C
read -r -d '' _ </dev/tty
