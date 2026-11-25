#!/bin/sh
# Grab one frame of the board's HDMI output (dock capture, ffmpeg NUT stream on localhost:5000).
# The stream starts with buffered (possibly stale) frames, so skip the first SKIP frames.
#   grab-frame.sh OUT.png
DEMO=$(cd "$(dirname "$0")" && pwd)
exec "$DEMO/nix" shell --inputs-from "path:$DEMO/kernel" nixpkgs#ffmpeg-headless -c \
	ffmpeg -loglevel error -y -f nut -i tcp://127.0.0.1:5000 -vf "select=gte(n\\,${SKIP:-90})" -frames:v 1 "$1"
