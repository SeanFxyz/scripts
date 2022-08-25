#!/bin/sh
grep 'model name' /proc/cpuinfo | head -n1 | sed 's/^.*: //'
