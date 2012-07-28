#!/bin/sh
set -x

bridge=br0
interface=$1

ifconfig $interface down
tunctl -d $interface
