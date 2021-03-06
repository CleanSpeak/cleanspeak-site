#!/usr/bin/env bash

# Note: if you make changes to this file, you will have to run sb push twice because the first execution will run the old version.

if [ ! "$(hostname)" = "cleanspeak" ]; then
  echo "You are only supposed to run this on cleanspeak.com, run sb push instead."
  exit 0
fi

set -e

export GEM_HOME=/var/git/cleanspeak-site/.gems

cd /var/git/cleanspeak-site

git pull

# Update to latest
bundle install

# Prevent dirty builds
bundle exec jekyll clean

bundle exec jekyll build

cp -R _site/* /var/www/cleanspeak.com
