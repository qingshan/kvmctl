#!/bin/bash

# Basic argument check
if [ ! $1 ]; then
    echo "Usage:"
    echo "$0 (start|stop|install|monitor|vnc|status) name"
    exit 1
fi
KVM_NAME=$2
KVM_CONFIG="./$KVM_NAME.cfg"
KVM_PID="./$KVM_NAME.pid"
KVM_IMAGE="./$KVM_NAME.img"
if [ -f $KVM_CONFIG ]; then
    . $KVM_CONFIG
else
    echo "KVM config file is not existed: $KVM_CONFIG"
    exit 1
fi

# Calculate TCP port for Monitor, starting at 1000
TCPPORT=`expr 1000 + $ID`

# Calculate TCP port for VNC console, starting at 5900
VNCPORT=`expr 5900 + $ID`

# Calculate MAC address
MACADDR="DE:AD:BE:EF:${USER}0:$(printf "%02X", $ID)"

if [ "$SNIFFER" = "true" ]; then
    SNIFFER_MACADDR="DE:AD:BE:EF:${USER}F:$(printf "%02X", $ID)"
    EXTRA_OPTS="$EXTRA_OPTS -net nic,vlan=1,macaddr=$SNIFFER_MACADDR -net tap,vlan=1,script=/etc/ifup-br1,downscript=/etc/ifdown-br1"
fi
if [ "$1" = "install" ]; then
    EXTRA_OPTS="$EXTRA_OPTS -boot d -cdrom $ISO"
fi
if [ ! $DISKS ]; then
    for i in ${!DISKS[*]}; do
        EXTRA_OPTS="$EXTRA_OPTS -drive file=${DISKS[$i]},index=$i,cache=none,media=disk"
    done
fi 

case "$1" in
start|install)
    echo -n "Starting KVM from $KVM_CONFIG: "
    /usr/libexec/qemu-kvm \
        -name $KVM_NAME \
        -hda $KVM_IMAGE \
        -m $MEMORY \
         -localtime \
        -net nic,vlan=0,macaddr=$MACADDR \
        -net tap,vlan=0 \
        -pidfile $KVM_PID \
        -vnc :$ID \
        -monitor tcp:127.0.0.1:$TCPPORT,server,nowait \
        $EXTRA_OPTS \
        -daemonize
    if [ $? -eq 0 ]
    then
        echo "Success. (VNC on $VNCPORT / ID, Monitor on $TCPPORT)"
    else
        echo "Failed. (Couldn't run KVM)"
    fi
    ;;
stop)
    echo "system_powerdown" | nc 127.0.0.1 $TCPPORT
    if [ $? -eq 0 ]
    then
        echo ""
        echo "Signaled powerdown to KVM in $KVM_NAME."
        sleep 60
        if [ -d /proc/$(cat $KVM_PID) ]; then
            pkill -f -- "-name $KVM_NAME"
        fi
        rm -f $KVM_PIDFILE
    else
        echo "Failed. (Couldn't connect to monitor. Is the machine up?)"
    fi
    ;;
monitor)
    echo "Starting Monitor for KVM in $KVM_NAME ****** Ctrl+C to exit."
    exec nc 127.0.0.1 $TCPPORT
    ;;
vnc)
    echo "Starting VNC for KVM in $KVM_NAME."
    exec vncviewer -AutoSelect=0 127.0.0.1:$ID
    ;;
status)
    echo -e "info status\ninfo kvm\ninfo network" |
        nc -w 1 127.0.0.1 $TCPPORT
    if [ $? -eq 0 ]
    then
        echo ""
    else
        echo "Error: couldn't connect to monitor. Is the machine up?"
    fi
    ;;
esac
