#!/bin/bash

# the original urlwatch is slow and buggy

if ((! $#)); then
    echo "cheap bash knockoff of urlwatch"
    echo "urlwatch.sh url-list.txt"
    exit
fi

urlfile=$1
diffargs=
cache=$HOME/.urlwatch/cache
mkdir -p "$cache"

COLOR1='\e[1;32m'
ENDC='\e[0m'

nap()  # none : none
{
    while (( $(jobs | wc -l) >= 16 )); do
        sleep 0.1
        jobs > /dev/null
    done
}

urlcheck()  # url : pretty print
{
    urlhash=$(sha1sum <<< "$1")
    urlhash=${urlhash%% *}
    temp=$(mktemp)
    curl -s --connect-timeout 10 "$1" > "$temp"
    if [[ ! -s $temp ]]; then
        # failure, don't bother anyone with the diff
        rm -f "$temp"
        return
    fi
    html2text -o "$temp.txt" "$temp"
    if [[ ! -e $cache/$urlhash ]]; then
        cp "$temp.txt" "$cache/$urlhash"
    fi
    if ! diff -q "$temp.txt" "$cache/$urlhash" &> /dev/null; then
        diff $diffargs "$temp.txt" "$cache/$urlhash" > "$temp.diff"
        cp "$temp.txt" "$cache/$urlhash"
        # echo is atomic, fine for multithreaded stuff
	# printf because nyeh *raspberry* $ help printf
        printf '%b\n%s\n\n' "${COLOR1}${1}${ENDC}" "$(< $temp.diff)"
    fi
    rm -f "$temp"{,.txt,.diff}
}

while read line; do
    # todo, filter comments
    urlcheck "$line" &
    nap
done < "$urlfile"
wait

