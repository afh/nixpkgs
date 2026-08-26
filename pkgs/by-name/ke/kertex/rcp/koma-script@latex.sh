#
# This is a strictly POSIX 1003.2 shell (Bourne shell) script
# automatically generated to add the LaTeX contrib: koma-script
# to kerTeX.
#
# No shebang, since there is a bootstrapping problem: this script has
# to run on whatever host the kerTeX system runs on.
# It has to be invoked with whatever Bourne shell like interpreter is
# present on the host.
#
# C) 2024 Thierry Laronde <tlaronde@polynum.com>
# All rights reserved and absolutely no warranty! Use at your own
# risks.
#

# Needed post action (build, apply, remove) routines.
#
pkg_post_build()
{
	return 0 # bash errors on empty function...
}

pkg_post_apply()
{
	return 0 # bash errors on empty function...
}

pkg_post_remove()
{
	return 0 # bash errors on empty function...
}

#==================== AUTOMATIC PROCESSING
# First include the pecularities of the TeX kernel system host.
#
. which_kertex >&2

# Then we now how to find the library that defines routines and does
# some checks, argument processing and initializations. See the file
# directly for explanations.
#
. $KERTEX_BINDIR/lib/pkglib.sh

#==================== CUSTOM PROCESSING: we are in TMPDIR
#
#
pkg_get

#===== Proceeding
#
# unzip
cd $TMPDIR/lib/$PKG_NAME/..
$PKG_UNZIP koma-script.zip
rm koma-script.zip
cd $TMPDIR/lib/$PKG_NAME/
$KERTEX_BINDIR/tex scrmain.ins

# If there are bibtex bibliography entries, put them in place and add
# the bibtex entry in KXPATH.
#
#for suffix in bst bib; do
#	has_some=NO
#	pkg_lstree | sed "/\.$suffix\$/!d" | while read file; do
#		if test $has_some = "NO"; then
#			mkdir -p $TMPDIR/lib/bibtex/koma-script/$suffix
#			ed -s $PKG_CID <<EOT
#/^KXPATH:/a
#	bibtex koma-script/$suffix
#.
#w
#q
#EOT
#			has_some=YES
#		fi
#    mv $file $TMPDIR/lib/bibtex/koma-script/$suffix/$(basename $file)
#	done
#done


# The path will be added by KXPATH. So we let files here.

#===== CUSTOM PROCESSING FINISHED
#
# Time to do whether the build or the install.
#
pkg_do_action

# not reached
exit 0

# Since we have exited above, no need to comment out the CID.

BEGIN_CID
NAME: latex/koma-script
VERSION: 3.49.2 2026-02-02
LICENCE: The LaTeX Project Public License 1.3c
KERTEX_VERSION: 0.99.27.00
AUTHOR: 1994–2026 Markus Kohm
DESCRIPTION:
  The KOMA-Script bundle provides replacements for the article,
  report, and book classes with emphasis on typography and
  versatility. There is also a letter class.
DEPENDENCIES:
  latex/etoolbox
  latex/xpatch
KXPATH:
	latex koma-script
SOURCES:
	LCD HOME/..
	GET /macros/latex/contrib/koma-script.zip
END:
END_CID
