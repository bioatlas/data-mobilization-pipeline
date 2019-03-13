#!/bin/bash

ORGANIZATION="4c415e40-1e21-11de-9e40-a0d6ecebb8bf"
INSTALLATION="4346b227-ca68-4d54-8a77-909148492e0b"

REMOTE="example.net:/var/www"
BASEURL="https://example.net"

for file in "$@"; do
  base=${file%%.*}

  # create the dataset unless it already exists, and store the id in a file
  if [ -f "$base.id" ]; then
    echo "skipping $base, already created" >&2
    id=$(cat $base.id)
  else
    id=$(reggie -t create SAMPLING_EVENT "temp" $ORGANIZATION $INSTALLATION)
    echo "$id" > "$base.id"
  fi

  # upload the dwca
  scp "$file" "$REMOTE/$id.zip"

  # wipe previous endpoints and set up a new one
  reggie -t wipe "$id"
  reggie -t endpoint "$id" "$BASEURL/$id.zip" "DwC-A"

  # ask for a crawl
  reggie -t crawl "$id"
done

