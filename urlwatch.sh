#!/bin/bash

# the original urlwatch is slow and buggy

if [ $# -eq 0 ]; then
    echo "cheap bash knockoff of urlwatch"
    echo "urlwatch.sh url-list.txt"
    exit
fi

urlfile="$1"
diffargs=""
cache="$HOME/.urlwatch/cache"
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
    urlhash=$(sha1sum <<< "$1" | cut -d ' ' -f 1)
    temp=$(mktemp)
    curl -s --connect-timeout 10 "$1" > "$temp"
    html2text -o "$temp.txt" "$temp"
    if [ ! -e "$cache/$urlhash" ]; then
        cp "$temp.txt" "$cache/$urlhash"
    fi
    diff -q "$temp.txt" "$cache/$urlhash" &> /dev/null
    if [[ "$?" != "0" ]]; then
        diff $diffargs "$temp.txt" "$cache/$urlhash" > "$temp.diff"
        cp "$temp.txt" "$cache/$urlhash"
        # echo is atomic, fine for multithreaded stuff
        echo -e "${COLOR1}${1}${ENDC}\n$(cat $temp.diff)\n\n"
    fi
    rm -f $temp
    rm -f $temp{.txt,.diff}
}

while read line; do
    # todo, filter comments
    urlcheck "$line" &
    nap
done < "$urlfile"
wait

