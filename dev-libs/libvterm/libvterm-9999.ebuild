# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

set -e

inherit bzr

DESCRIPTION="An abstract C99 library which implements a VT220 or xterm-like terminal emulator"
HOMEPAGE="http://www.leonerd.org.uk/code/libvterm/"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

EBZR_REPO_URI="http://bazaar.leonerd.org.uk/c/libvterm/"

DEPEND=""
RDEPEND="${DEPEND}"

src_test() {
	emake test
}

src_install() {
	emake PREFIX="${D}/usr" install
}
