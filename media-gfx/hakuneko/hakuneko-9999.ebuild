# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI="6"

# wxGTK version required by HakuNeko.
WX_GTK_VER=3.0

inherit wxwidgets

DESCRIPTION="Manga downloader"
HOMEPAGE="https://sourceforge.net/projects/hakuneko"

LICENSE="MIT"
SLOT="0"
IUSE="clang"
REQUIRED_USE=""

RDEPEND="
	net-misc/curl:=[ssl]
	dev-libs/openssl:=
	x11-libs/wxGTK:3.0=[X]
"
DEPEND="${RDEPEND}
	clang? ( sys-devel/clang )
	!clang? ( sys-devel/gcc[cxx] )
"

if [[ ${PV} == 9999 ]]; then
	inherit mercurial

	EHG_REPO_URI="http://hg.code.sf.net/p/hakuneko/code"
	KEYWORDS=""
else
	MY_P="${PN}_${PV}_src"
	SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

src_prepare() {
	# Remove (in order):
	#
	# * Hard-coded optimizations from ${CFLAGS}.
	# * Debug symbol stripping from ${LDFLAGS}.
	sed -e '/-O2$/d' \
		-e '/^LDFLAGS=/s~-s~~' \
		-i config_default.sh || die '"sed" failed.'

	# Apply user-specific patches.
	eapply_user
}

src_configure() {
	# The "configure" script accepts non-standard options prefixed by
	# "--config-". Why? Just because.
	econf $(usex clang "--config-clang" "")
}

src_install() {
	# Install documentation to version-specific rather than -agnostic paths.
	# While the "configure" script could be patched to effect this as well, the
	# current approach is substantially simpler and more robust. It's a win-win.
	mv build/linux/share/doc/${PN} build/linux/share/doc/${P} ||
		die '"mv" failed.'

	# Install HakuNeko.
	default_src_install
}
