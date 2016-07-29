# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vice/vice-2.4.ebuild,v 1.10 2013/06/04 20:41:32 mr_bones_ Exp $
EAPI=5

# Enable Bash strictness.
set -e

inherit cmake-utils

MY_PN="munt"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Software synthesiser emulating pre-GM MIDI devices"
HOMEPAGE="http://munt.sourceforge.net"
SRC_URI="mirror://sourceforge/${MY_PN}/${PV}/${MY_P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="media-libs/portaudio"
DEPEND="${RDEPEND}
	sys-devel/gcc[cxx]
"

S="${WORKDIR}/${MY_P}/${PN}"

pkg_setup() {
	ewarn 'Deprecation Warning: "media-libs/mt32emu" is now obsolete.'
	ewarn 'Consider installing "media-libs/munt".'
}

src_prepare() {
    cmake-utils_src_prepare

    # Install documentation to the expected system-wide path.
	sed -i -e "s~share/doc/munt/libmt32emu~share/doc/${P}~" CMakeLists.txt
}
