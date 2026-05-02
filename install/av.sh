#!/usr/bin/env bash

set -euo pipefail

sudo xbps-install -Sy mpv ffmpeg gstreamer1 gst-libav \
	gst-plugins-bad1 gst-plugins-base1 gst-plugins-good1 gst-plugins-ugly1 \
	gstreamer1-pipewire
