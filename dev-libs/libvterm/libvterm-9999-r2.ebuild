# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

inherit multilib bzr flag-o-matic

DESCRIPTION="Abstract library implementation of a VT220/xterm/ECMA-48 terminal emulator"
HOMEPAGE="http://www.leonerd.org.uk/code/libvterm"
EBZR_REPO_URI="http://bazaar.leonerd.org.uk/c/libvterm"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="test"

DEPEND=""
RDEPEND="!dev-libs/libvterm-neovim"

src_prepare() {
	# Prevent "libtool" from emitting ignorable warnings during installation
	# resembling:
	#
	#     libtool: warning: '/var/tmp/portage/dev-libs/libvterm-9999-r2/work/libvterm-9999/libvterm.la' has not been installed in '/usr/local/lib'
	#     libtool: warning: remember to run 'libtool --finish /usr/local/lib'
	#
	# We pass both "--no-warnings" *AND* "--warnings=none" to guarantee this.
	# While "man libtool" insists that the former is a synonym for the latter,
	# this does *NOT* appear to be the case. Welcome to libtool hell.
	sed -i -e '/LIBTOOL +=/s~+=~+=--no-warnings --warnings=none ~' Makefile ||
		die '"sed" failed.'
}

src_test() {
	# Ideally, valgrind-specific unit tests could be reliably enabled by
	# passing "VALGRIND=1". Sadly, such tests currently fail with:
	#     valgrind:  Fatal error at startup: a function redirection
	#     valgrind:  which is mandatory for this platform-tool combination
	#     valgrind:  cannot be set up.
	emake test || die 'Functional tests failed.'
}

src_install() {
	# By default, the Makefile installs to "/usr/local/lib". That's terrible.
	emake PREFIX="${D}/usr" LIBDIR="${D}/usr/$(get_libdir)" install ||
		die 'Installation failed.'
	dodoc doc/URLs doc/seqs.txt
}

src_compile() {
	# NeoVim requires the "-fPIC" CFLAG. See also:
	#     https://github.com/neovim/neovim/pull/2076
	append-cflags -fPIC
	emake || die 'Compilation failed.'
}
