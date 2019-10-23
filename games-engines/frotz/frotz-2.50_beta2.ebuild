# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs

MY_PV="${PV/_beta/b}"
MY_P="${PN}-${MY_PV}"
DESCRIPTION="Interpreter for Z-code based text games"
HOMEPAGE="https://661.org/proj/if/frotz/"
SRC_URI="https://gitlab.com/DavidGriffith/${PN}/-/archive/${MY_PV}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="ncurses sdl sound unicode"
REQUIRED_USE="sound? ( || ( ncurses sdl ) )"

DEPEND="
	ncurses? (
		sys-libs/ncurses:0=[unicode?]
		sound? (
			>=media-libs/libao-1.1.0
			>=media-libs/libmodplug-0.8.8.4
			>=media-libs/libsamplerate-0.1.8[sndfile]
			>=media-libs/libsndfile-1.0.25
			>=media-libs/libvorbis-1.3.2
		)
	)
	sdl? (
		>=media-libs/freetype-2.6.0:2
		>=media-libs/libjpeg-turbo-1.5.0:0=
		>=media-libs/libpng-1.6.0:0=
		>=media-libs/libsdl2-2.0.9[sound,threads,video]
		>=media-libs/sdl2-mixer-2.0.4
		>=sys-libs/zlib-1.2.0
	)
"

RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

src_compile() {
	emake \
		dumb \
		$(use ncurses && echo ncurses) \
		$(use sdl && echo sdl) \
		AR="$(tc-getAR)" \
		CC="$(tc-getCC)" \
		PKG_CONFIG="$(tc-getPKG_CONFIG)" \
		RANLIB="$(tc-getRANLIB)" \
		CURSES=$(usex unicode ncursesw ncurses) \
		USE_UTF8=$(usex unicode yes "") \
		SOUND=$(usex sound ao none) \
		PREFIX="${EPREFIX}/usr" \
		SYSCONFDIR="${EPREFIX}/etc"
}

src_install () {
	emake \
		install_dumb \
		$(use ncurses && echo install) \
		$(use sdl && echo install_sdl) \
		PREFIX="${EPREFIX}/usr" \
		DESTDIR="${D}"

	dodoc \
		AUTHORS ChangeLog CONTRIBUTORS DUMB HOW_TO_PLAY README TODO \
		doc/frotz.conf-{big,small}
}

pkg_postinst() {
	echo
	elog "Global config file can be installed in ${EPREFIX}/etc/frotz.conf"
	elog "Sample config files are in ${EPREFIX}/usr/share/doc/${PF}"
	echo
}
