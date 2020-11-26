#!/bin/bash

# grab-banner.sh
#
# Bash script that performs generic banner grabbing, multiple ports per host
#
# Version 1.0.1
#
# Copyright (C) 2016 Jonathan Elchison <JElchison@gmail.com>


# setup Bash environment
set -uf -o pipefail

# setup variables
SERVICES_FILE=/etc/services


###############################################################################
# functions
###############################################################################

# Prints script usage to stderr
# Arguments:
#   None
# Returns:
#   None
print_usage() {
    echo "Usage:    $0 <IPrange>" >&2
    echo "Example:  $0 192.168.1.0" >&2
}

# Check validity of IP range
# Arguments:
#   IP range
# Returns:
#   0:valid
#   1:unvalid
check_iprange() {
    local valid=0
    local iprange=$1

    if [[ ! "$iprange" =~ ^[0-9]{3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	$valid=1
	echo $valid
    else
	echo $valid
    fi
}

###############################################################################
# test dependencies
###############################################################################

if [[ ! -x $(which awk) ]]; then
    echo "[-] ERROR: Required dependencies unmet. Please verify that the following are installed, executable, and in the PATH:  awk" >&2
    exit 1
fi

if [[ ! -x $(which curl) ]]; then
    echo "[-] WARNING: Optional dependencies unmet. Please verify that the following are installed, executable, and in the PATH:  curl" >&2
fi

if [[ ! -r $SERVICES_FILE ]]; then
    echo "[-] WARNING: Optional dependencies unmet. Please verify that the following file is present and readable:  $SERVICES_FILE" >&2
fi


###############################################################################
# validate arguments
###############################################################################

# require at least 1 arguments
if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
fi

valid=`check_iprange $1`
if [[ $valid != 0 ]]; then
    print_usage
    exit 1
fi

# setup variables for arguments
iprange=$1

firstbyte=$(echo $iprange | cut -d . -f 1)
secondbyte=$(echo $iprange | cut -d . -f 2)
thirdbyte=$(echo $iprange | cut -d . -f 3)
fourthbyte=$(echo $iprange | cut -d . -f 4)


###############################################################################
# grab banners on hosts in the range
###############################################################################

shift
for fourthbyte in `seq 1 254`; do
    HOST="$firstbyte.$secondbyte.$thirdbyte.$fourthbyte"
    PORT=80
    echo "[*] =====================================================" >&2
    echo "[+] Grabbing banner from $HOST:$PORT [$(grep "[^0-9]$PORT/tcp" $SERVICES_FILE | awk '{print $1}')] ..." >&2
    echo "[*] =====================================================" >&2

    curl -s -D - -o /dev/null "http://$HOST"
    
    PORT=443
    echo "[*] =====================================================" >&2
    echo "[+] Grabbing banner from $HOST:$PORT [$(grep "[^0-9]$PORT/tcp" $SERVICES_FILE | awk '{print $1}')] ..." >&2
    echo "[*] =====================================================" >&2

    curl -k -s -v -D - "https://$HOST" > /dev/null
    echo >&2
done
