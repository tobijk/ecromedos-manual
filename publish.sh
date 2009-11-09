#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 <revision>"
	exit 1
else
	tag="$1"
fi

git checkout $tag || {
	echo "Could not checkout tag '$tag' :("
	exit 2
}

mkdir tmp html pdf

(cd html &&
	ecromedos -fxhtml ../src/manual.xml) > /dev/null

(cd tmp &&
	ecromedos -fxelatex ../src/manual.xml &&
	for i in `seq 3`; do
		xelatex report.tex
	done &&
	mv report.pdf ../pdf/manual.pdf) > /dev/null

rm -fr tmp
