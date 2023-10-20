#!/bin/bash
SECRET=$1
read DATA
PREFIXED="$SECRET|$DATA"
echo data to sign is:$PREFIXED
SIGNATURE=$(echo -n $PREFIXED | sha1sum - | awk -p '{print $1}')
echo signature is ${SIGNATURE}
B64=$(echo -n "${DATA}|${SIGNATURE}" | base64 -w 0)
echo signed and encoded: $B64

