#!/bin/bash

# Function to log messages
log_message() {
    if [ "$verbose" = true ]; then
        echo "$1"
    fi
    logger -t configure-host.sh "$1"
}

# Default values
verbose=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -verbose)
        verbose=true
        shift
        ;;
        -name)
        desiredName="$2"
        shift
        shift
        ;;
        -ip)
        desiredIPAddress="$2"
        shift
        shift
        ;;
        -hostentry)
        desiredName="$2"
        desiredIPAddress="$3"
        shift
        shift
        shift
        ;;
        *)
        shift
        ;;
    esac
done

# Check if TERM, HUP, and INT signals are received
trap '' TERM HUP INT

# Configure host name for Server1 (loghost)
if [ -n "$desiredName" ]; then
    currentName=$(hostname)
    if [ "$currentName" != "$desiredName" ]; then
        echo "$desiredName" > /etc/hostname
        sed -i "/127.0.1.1/c\127.0.1.1    $desiredName" /etc/hosts
        hostname "$desiredName"
        log_message "Hostname changed to $desiredName"
    else
        log_message "Hostname is already $desiredName"
    fi
fi

# Configure host name for Server2 (webhost)
if [ -n "$desiredName" ]; then
    currentName=$(hostname)
    if [ "$currentName" != "$desiredName" ]; then
        echo "$desiredName" > /etc/hostname
        sed -i "/127.0.1.1/c\127.0.1.1    $desiredName" /etc/hosts
        hostname "$desiredName"
        log_message "Hostname changed to $desiredName"
    else
        log_message "Hostname is already $desiredName"
    fi
fi

# Configure IP address (if needed)
if [ -n "$desiredIPAddress" ]; then
    currentIPAddress=$(ip -br addr show | awk '{print $3}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1')
    if [ "$currentIPAddress" != "$desiredIPAddress" ]; then
        sed -i "/$currentIPAddress/d" /etc/hosts
        sed -i "/addresses:/,+2 s/.addresses:./      addresses: [$desiredIPAddress\/24]/" /etc/netplan/*.yaml
        netplan apply
        log_message "IP address changed to $desiredIPAddress"
    else
        log_message "IP address is already $desiredIPAddress"
    fi
fi
