#!/bin/bash

function usage {
	echo "Usage: debian/package.sh <tag> <outdir>"
}

if [ $# -ne 2 ] || [ -z "`echo $0 | egrep '^debian/'`" ]; then
	usage
	exit 1
fi

TAG=$1
OUTDIR=$2
OLD_BRANCH=`git branch | egrep "^\*" | cut -d' ' -f2`
TMPDIR="`mktemp -d`"

test -d ${OUTDIR} || {
	echo "No such directory '$OUTDIR'."
	exit 2
}

OUTDIR=$(cd ${OUTDIR} && pwd)

git checkout $TAG > /dev/null 2>&1 || {
	echo "Could not check out tag $TAG."
	exit 3
}

git checkout $OLD_BRANCH > /dev/null 2>&1

echo "Building package in $TMPDIR:"

git archive --prefix=ecromedos-doc-${TAG}/ --format=tar ${TAG} | \
	(cd ${TMPDIR} && \
	tar -x --exclude=.gitignore --exclude=debian -f - && \
	tar -czf ecromedos-doc_${TAG}.orig.tar.gz ecromedos-doc-${TAG} \
	&& rm -fr ecromedos-doc-${TAG})

git archive --prefix=ecromedos-${TAG}/ --format=tar pkg-deb | \
	(cd ${TMPDIR} && tar -x --exclude=.gitignore --exclude=debian/package.sh -f -)

(cd ${TMPDIR}/ecromedos-doc-${TAG} &&
	dpkg-buildpackage -us -uc &&
	cd .. &&
	mv *.{changes,deb,dsc,diff.gz,tar.gz} ${OUTDIR})

rm -fr ${TMPDIR}

echo "Collect package from $OUTDIR."

