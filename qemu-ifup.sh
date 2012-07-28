#!/bin/sh
set -x

bridge=br0
interface=$1

/sbin/ip link set $interface up
/usr/sbin/brctl addif $bridge $interface
