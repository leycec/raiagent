# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vice/vice-2.4.ebuild,v 1.10 2013/06/04 20:41:32 mr_bones_ Exp $
EAPI=5

# Enable Bash strictness.
set -e

inherit readme.gentoo

MY_PN="munt"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="MT-32 ALSA MIDI daemon"
HOMEPAGE="http://munt.sourceforge.net"
SRC_URI="mirror://sourceforge/${MY_PN}/${PV}/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	x11-libs/libXpm
	x11-libs/libXt
	~media-libs/mt32emu-${PV}
	>=media-libs/alsa-lib-0.9.1
"
DEPEND="${RDEPEND}
	sys-devel/gcc[cxx]"

S="${WORKDIR}/${MY_P}/mt32emu_alsadrv"

pkg_setup() {
	ewarn 'Deprecation Warning: "media-libs/mt32emu-alsa" is now obsolete.'
	ewarn 'Consider installing "media-libs/munt" with the "alsa" USE flag.'
}

src_prepare() {
	# Install "mt32d" to the expected path, strip ${CXXFLAGS}, and prevent the
	# makefile from failing on attempting to glob non-existent ROM files (i.e.,
	# lines beginning with "cd ").
	sed -i\
		-e "/CXXFLAGS=-O2/d"\
		-e "/^\s*cd /d"\
		-e "s~ /usr/local/bin~ ${D}/usr/bin~"\
		-e "s~ /usr/~ ${D}/usr/~"\
		"Makefile"
}

src_install() {
	# Make paths expected by the makefile installer. (Thanks alot!)
	mkdir -p "${D}"/usr/{bin,share}
	mkdir roms 
	touch roms/.keep

	# Run the makefile installer.
	emake install

	# Install the daemon service.
	newconfd "${FILESDIR}/conf" "${PN}"
	newinitd "${FILESDIR}/init" "${PN}"

	# Make directories expected by the daemon service.
	keepdir /var/log/${PN}

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	Manually download and install the original Roland MT-32 ROM files
	\"MT32_CONTROL.ROM\" and \"MT32_PCM.ROM\" to \"/usr/share/mt32-rom-data\".\\n
	\\n
	After installation, add \"${PN}\" to the default runlevel: e.g.,\\n
	\\trc-update add ${PN} default\\n
	\\n
	The \"${PN}\" service provides ALSA port 128:0 for playing MT-32 MIDI
	streams (if \"${PN}\" is the only currently running ALSA soft-synth)."

	# Install such document.
	readme.gentoo_create_doc
}

pkg_postinst() {
	# On first installations of this package, elog the contents of the
	# previously installed "/usr/share/doc/${P}/README.gentoo" file.
	readme.gentoo_print_elog
}
