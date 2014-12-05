# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5
PLOCALES="ar_SA bg_BG cs_CZ de_DE el_GR it_IT lt_LT ru_RU vi_VN uk_UA zh_CN"

inherit l10n qt4-r2

MY_PV="${PV/_rc/-RC}"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="Feature-rich dictionary lookup program"
HOMEPAGE="http://goldendict.org"
SRC_URI="https://github.com/goldendict/goldendict/archive/${MY_PV}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug kde"

RDEPEND="
	app-arch/bzip2:=
	dev-libs/lzo:2=
	>=app-text/hunspell-1.2:=
	media-libs/libao:=
	media-libs/libogg:=
	media-libs/libvorbis:=
	sys-libs/zlib:=
	x11-libs/libX11:=
	x11-libs/libXtst:=
	x11-proto/recordproto:=
	virtual/ffmpeg:=
	>=dev-qt/qtcore-4.5:4=[exceptions,qt3support]
	>=dev-qt/qtgui-4.5:4=[exceptions,qt3support]
	>=dev-qt/qtwebkit-4.5:4=[exceptions]
	!kde? ( || (
		>=dev-qt/qtphonon-4.5:4=[exceptions]
		media-libs/phonon:=
	) )
	kde? ( media-libs/phonon:= )
"
DEPEND="${RDEPEND}
	!app-text/goldendict
	virtual/pkgconfig
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	qt4-r2_src_prepare

	# Print discrepancies between ${PLOCALES} and actual locale files.
	l10n_find_plocales_changes "${S}"/locale "" .ts

	# Avoid installing locales unsupported by Gentoo.
	disable_locale() {
		sed -e "s;locale/${1}.ts;;" -i ${PN}.pro || die
	}
	l10n_for_each_disabled_locale_do disable_locale

	# Avoid installing duplicates.
	sed -e '/[icon,desktop]s2/d' -i ${PN}.pro || die

	# Append a missing trailing semicolon to the desktop file.
	sed -e '/^Categories=/s/;Applications$/;/' -i redist/${PN}.desktop || die
}

src_install() {
	qt4-r2_src_install

	install_locale() {
		insinto /usr/share/apps/${PN}/locale
		doins locale/${1}.qm
	}
	l10n_for_each_locale_do install_locale
}
