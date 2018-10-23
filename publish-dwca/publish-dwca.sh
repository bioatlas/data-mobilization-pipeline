#!/bin/bash

TYPE="SAMPLING_EVENT"

ORGANIZATION="<ORGANIZATION ID>"
INSTALLATION="<INSTALLATION ID>"

REMOTE="server:/path"
BASEURL="http://server/path"

for file in "$@"; do
  base=${file%%.*}

  # create the dataset unless it already exists, and store the id in a file
  if [ -f "$base.id" ]; then
    echo "skipping $base, already created" >&2
    id=$(cat $base.id)
  else
    id=$(reggie -t create $TYPE "a dataset" $ORGANIZATION $INSTALLATION)
    echo "$id" > "$base.id"
  fi

  # scp the dwca file
  scp "$file" "$REMOTE/$id.zip"

  # wipe previous endpoints and set up a new one
  reggie -t wipe "$id"
  reggie -t endpoint "$id" "$BASEURL/$id.zip" "DwC-A"

  # ask for a crawl
  reggie -t crawl "$id"
done

