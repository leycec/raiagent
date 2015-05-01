# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

inherit perl-app

DESCRIPTION="Perl script which is designed to apply an IPS patch to a ROM"
HOMEPAGE="http://www.zophar.net/utilities/patchutil/ips-pl.html"
SRC_URI="http://www.zophar.net/fileuploads/1/3142ixteo/ips.txt -> ${P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=
REQUIRED_USE=

RDEPEND=
DEPEND=

S="${WORKDIR}"

src_unpack() {
	cp "${DISTDIR}/${P}" "${S}/" || die '"cp" failed.'
}

src_install() {
	newbin ${P} ${PN}
	perl-module_src_install
}
