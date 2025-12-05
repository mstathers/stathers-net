#!/usr/bin/env bash

TAGS=()

# Adding tag files.
for tag in $(grep -h tags: ./_posts/* | sed -e 's/^tags: //' | tr ' ' '\n' | sort | uniq); do
        TAGS+=($tag)

        if [ -a ./tag/${tag}.md ]; then
            echo "Already have a tag file for $tag, skipping..."
            continue
        fi

        echo "Generated a tag file for $tag"

        echo "---
layout: tagpage
title: \"Tag: #$tag\"
tag: $tag
robots: noindex
---" > ./tag/${tag}.md;
done


# Removing unused tag files.
for file in $(ls ./tag/); do
    exists=false
    for tag in ${TAGS[@]}; do
        if [[ $tag == $(echo $file | cut -d'.' -f1) ]]; then
            exists=true
            break
        fi
    done
    if ! $exists; then
        echo "$file doesn't match a tag, removing..."
        rm -f ./tag/$file
    fi

done

