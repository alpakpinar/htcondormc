#!/bin/bash

voms-proxy-init --voms cms --valid 192:00

PROXY_FILE="/tmp/x509up_u118821"

DESTINATION="${HOME}/private"

cp ${PROXY_FILE} ${DESTINATION}

echo "${PROXY_FILE} copied to ${DESTINATION}"

ls -lah ${DESTINATION}

