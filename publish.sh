#!/bin/bash

output=all
while true; do
	case "$1" in
		--html-only)
			output=html
			shift
		;;
		--pdf-only)
			output=pdf
			shift
		;;
		*)
			break
		;;
	esac
done

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

mkdir -p tmp html pdf

if [ $output = 'all' ] || [ $output = 'html' ]; then
	(cd html &&
	ecromedos -fxhtml ../src/manual.xml) > /dev/null
fi

if [ $output = 'all' ] || [ $output = 'pdf' ]; then
	(cd tmp &&
	ecromedos -fxelatex -s ../style/latex-style.xml ../src/manual.xml &&
	for i in `seq 3`; do
		xelatex book.tex
	done &&
	mv book.pdf ../pdf/manual.pdf) > /dev/null 2>&1
fi
rm -fr tmp
