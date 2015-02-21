# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

inherit bzr

DESCRIPTION="C99 library implementing VT220 and xterm-like terminal emulators"
HOMEPAGE="http://www.leonerd.org.uk/code/libvterm"
EBZR_REPO_URI="http://bazaar.leonerd.org.uk/c/libvterm"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_test() {
	emake test
}

# src_install() {
# 	emake PREFIX="${D}/usr" install
# }
