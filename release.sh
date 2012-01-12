#!/bin/bash

###############################################################################

ERR_USAGE=1
ERR_NOTAG=2
ERR_NODIR=3
ERR_TAGNO=4

###############################################################################

usage()
{
	echo "Usage: release.sh <tag> <outdir>"
}

error()
{
	local code=$1
	local msg=$2
	echo "$msg" >&2
	exit $code
}

check_tag()
{
	local tag=$1
	local current_branch=`git branch | egrep "^\*" | cut -d' ' -f2`

	# check for tag
	git checkout $tag > /dev/null 2>&1 || {
		error $ERR_NOTAG "Could not check out tag '$tag'."
	}

	if [ -n "$current_branch" ]; then
		git checkout $current_branch > /dev/null 2>&1
	else
		git checkout $master > /dev/null 2>&1
	fi
}

check_outdir()
{
	local outdir=$1

	# check for existence
	test -d "$outdir" || {
		echo "No such directory '$outdir'."
		exit $ERR_NODIR
	}
}

build_rpm()
{
	local tag=$1
	local outdir=$2
	local tmpdir="`mktemp -d`"

	echo -n "Building RPM package in $tmpdir..."

	# create rpm build subdirs
	mkdir -p $tmpdir/{RPMS,BUILD,SOURCES,SPECS,SRPMS}

	# build tarball
	git archive --prefix=ecromedos-doc-${tag}/ --format=tar ${tag} | \
		(cd ${tmpdir}/SOURCES && \
		tar -x \
			--exclude=.gitignore \
			--exclude=debian \
			--exclude=ecromedos-doc.spec \
			--exclude=package.sh -f - && \
		tar -czf ecromedos-doc-${tag}.tar.gz ecromedos-doc-${tag} && \
		rm -fr ecromedos-doc-${tag})

	# update tag in spec file
	cat ecromedos-doc.spec | sed "s/###TAG###/$tag/" > \
		$tmpdir/SPECS/ecromedos-doc-${tag}.spec

	# build package
	if [ $DEBUG ]; then
		rpmbuild --nodeps --target="noarch" --define="%_topdir $tmpdir" \
			-ba $tmpdir/SPECS/ecromedos-doc-${tag}.spec
	else
		rpmbuild --nodeps --target="noarch" --define="%_topdir $tmpdir" \
			-ba $tmpdir/SPECS/ecromedos-doc-${tag}.spec > /dev/null
	fi

	# fetch build artifacts
	mv $tmpdir/RPMS/*/*.rpm $outdir/rpm
	mv $tmpdir/SRPMS/*.rpm $outdir/rpm

	# cleanup
	rm -fr $tmpdir

	echo "done"
}

build_tgz()
{
	local tag=$1
	local outdir=$2
	local tmpdir="`mktemp -d`"

	echo -n "Building TGZ package in $tmpdir..."

	# build tarball
	git archive --prefix=ecromedos-doc-${tag}/ --format=tar ${tag} | \
		(cd ${tmpdir} && \
		tar -x \
			--exclude=.gitignore \
			--exclude=debian \
			--exclude=ecromedos-doc.spec \
			--exclude=package.sh -f - && \
		fakeroot tar -czf ecromedos-doc-${tag}.tar.gz ecromedos-doc-${tag} && \
		rm -fr ecromedos-doc-${tag})

	# fetch build artifacts
	mv $tmpdir/ecromedos-doc-${tag}.tar.gz ${outdir}/tgz

	# cleanup
	rm -fr $tmpdir

	echo "done"
}

build_deb()
{
	local tag=$1
	local outdir=$2
	local tmpdir="`mktemp -d`"

	echo -n "Building Debian package in $tmpdir..."

	# build orig-tarball
	git archive --prefix=ecromedos-doc-${tag}/ --format=tar ${tag} | \
		(cd ${tmpdir} && \
		tar -x \
			--exclude=.gitignore \
			--exclude=debian \
			--exclude=ecromedos-doc.spec \
			--exclude=package.sh -f - && \
		tar -czf ecromedos-doc_${tag}.orig.tar.gz ecromedos-doc-${tag} && \
		rm -fr ecromedos-doc-${tag})

	# extract plain sources with debian-dir
	git archive --prefix=ecromedos-doc-${tag}/ --format=tar ${tag} | \
		(cd ${tmpdir} && \
		tar -x \
			--exclude=.gitignore \
			--exclude=ecromedos-doc.spec \
			--exclude=package.sh -f -)

	# build packages
	(cd ${tmpdir}/ecromedos-doc-${tag} &&
		dpkg-buildpackage -us -uc &&
		cd .. &&
		mv *.{changes,deb,dsc,diff.gz,tar.gz} ${outdir}/deb)

	# cleanup
	rm -fr ${tmpdir}

	echo "done"
}

###############################################################################

if [ $# -ne 2 ]; then
	usage
	exit $ERR_USAGE
fi

TAG=$1
OUTDIR=$2

# SANITY CHECKS
check_outdir $OUTDIR
check_tag $TAG

# GET ABS PATH FOR OUTDIR
OUTDIR="`cd ${OUTDIR} && pwd`"

# MAKE SUBDIRS
mkdir $OUTDIR/{deb,tgz,rpm}

# BUILD PACKAGES
build_rpm $TAG $OUTDIR
build_tgz $TAG $OUTDIR
build_deb $TAG $OUTDIR

echo "Collect artifacts from $OUTDIR."

