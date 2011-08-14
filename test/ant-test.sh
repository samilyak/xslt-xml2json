#!/bin/sh

cd "$(dirname "$0")/../build" && \
ant clean test -lib "../lib/saxon"
