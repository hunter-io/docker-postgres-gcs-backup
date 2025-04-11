#! /bin/sh

# Exit if a command fails
set -e

# Update
apk update

# Install pg_dump
apk add --no-cache postgresql14-client pigz

# Cleanup
rm -rf /var/cache/apk/*
