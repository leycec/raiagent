# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5
EGIT_REPO_URI="https://github.com/goldendict/goldendict.git"
PLOCALES="ar_SA be_BY bg_BG cs_CZ de_DE el_GR es_AR es_ES fa_IR fr_FR it_IT ja_JP ko_KR lt_LT mk nl_NL pl_PL ru_RU sk_SK sq sr sv_SE tg_TJ tk tr_TR uk_UA vi_VN zh_CN zh_TW"

inherit l10n git-r3 qt4-r2

MY_PV="1.5.0-RC"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="Feature-rich dictionary lookup program"
HOMEPAGE="http://goldendict.org"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="debug epwing lzma sound tiff kde"

RDEPEND="
	app-arch/bzip2:=
	dev-libs/lzo:2=
	>=app-text/hunspell-1.2:=
	media-libs/libogg:=
	media-libs/libvorbis:=
	sys-libs/zlib:=
	x11-libs/libX11:=
	x11-libs/libXtst:=
	x11-proto/recordproto:=
	>=dev-qt/qtcore-4.5:4=[exceptions,qt3support]
	>=dev-qt/qtgui-4.5:4=[exceptions,qt3support]
	>=dev-qt/qthelp-4.5:4=[exceptions]
	>=dev-qt/qtwebkit-4.5:4=[exceptions]
	!kde? ( || (
		>=dev-qt/qtphonon-4.5:4=[exceptions]
		media-libs/phonon:=
	) )
	kde? ( media-libs/phonon:= )
	epwing? ( dev-libs/eb:= )
	lzma? ( app-arch/xz-utils:= )
	tiff? ( media-libs/tiff:0= )
	sound? (
		media-libs/libao:=
		virtual/ffmpeg:=
	)
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
"

src_unpack() {
	git-r3_src_unpack
	qt4-r2_src_unpack
}

src_prepare() {
	qt4-r2_src_prepare

	# print discrepancies between ${PLOCALES} and actual locale files
	l10n_find_plocales_changes "${S}/locale" "" ".ts"

	disable_locale() {
		sed -e "s;locale/${1}.ts;;" -i ${PN}.pro || die
	}
	l10n_for_each_disabled_locale_do disable_locale

	# do not install duplicates
	sed -e '/[icon,desktop]s2/d' -i ${PN}.pro || die

	# fix desktop file
	sed -e '/^Categories=/s/Qt$/Qt;/' -i redist/${PN}.desktop || die
}

src_configure() {
	local -a qmake_options
	use epwing || qmake_options+="CONFIG+=no_epwing_support"
	use lzma && qmake_options+="CONFIG+=zim_support"
	use sound || qmake_options+="DISABLE_INTERNAL_PLAYER=1"
	use tiff || qmake_options+="CONFIG+=no_extra_tiff_handler"
	# echo "qmake_options: ${qmake_options[*]}"

	PREFIX="${EPREFIX}"/usr eqmake4 ${PN}.pro "${qmake_options[@]}"
}

src_install() {
	qt4-r2_src_install

	install_locale() {
		insinto /usr/share/apps/${PN}/locale
		doins locale/${1}.qm
	}
	l10n_for_each_locale_do install_locale
}
