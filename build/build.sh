#!/bin/sh

cd "$(dirname "$0")" && \
ant clean main -lib "../lib/saxon"
