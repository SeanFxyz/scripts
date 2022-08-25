#!/bin/sh

if [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ -z "$@" ]; then
    printf "Usage: $0 [-h] [--help]\n"
    printf "       $0 FILE [FILE(s)...]\n"
fi

targets=$@
while [ -n "$1" ]; do
    t_sloc="$(grep '[^[:space:]]' "$1" | wc -l)"
    printf '%s\t%s\n' "$t_sloc" "$1"
    sloc=$((sloc + t_sloc))
    shift
done
printf '%s\n' "$sloc"
