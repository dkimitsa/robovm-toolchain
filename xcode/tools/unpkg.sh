#!/bin/bash
set -e

payload_file=`xar -tf $1 Payload`
xar -xf $1 Payload
tar -xf "$payload_file"
