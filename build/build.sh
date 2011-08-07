#!/bin/sh

OUT="xml2json.xsl"

xsltproc -o "$OUT" build.xsl ../src/xml2json.xsl &&
echo "Build result saved to file $OUT"
