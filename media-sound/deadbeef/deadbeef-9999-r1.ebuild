# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

#FIXME: Enable support for currently ignored USE flags, including:
#   archive bookmark-manager bs2b decast filebrowser gnome-mmkeys infobar
#   jack librarybrowser mpris musical-spectrum opus quick-search
#   replaygain-control soxr spectrogram statusnotifier stereo-widener
#   vk vu-meter waveform-seekbar

inherit autotools gnome2-utils l10n xdg-utils

DESCRIPTION="foobar2k-like music player"
HOMEPAGE="
	https://deadbeef.sourceforge.io
	https://github.com/DeaDBeeF-Player/deadbeef"

LICENSE="
	BSD UNICODE ZLIB
	aac? ( GPL-1 GPL-2 )
	adplug? ( LGPL-2.1 ZLIB )
	alac? ( MIT GPL-2 )
	alsa? ( GPL-2 )
	cdda? ( GPL-2 LGPL-2 GPL-3 )
	cdparanoia? ( GPL-2 )
	cover? ( ZLIB )
	converter? ( GPL-2 )
	curl? ( MIT ZLIB )
	dts? ( GPL-2 )
	dumb? ( DUMB-0.9.3 ZLIB )
	equalizer? ( GPL-2 )
	ffmpeg? ( GPL-2 )
	flac? ( BSD )
	gme? ( LGPL-2.1 )
	gtk2? ( GPL-2 )
	gtk3? ( GPL-2 )
	hotkeys? ( ZLIB )
	lastfm? ( GPL-2 )
	libav? ( GPL-2 )
	libnotify? ( GPL-2 )
	libsamplerate? ( GPL-2 )
	m3u? ( ZLIB )
	mac? ( GPL-2 )
	mad? ( GPL-2 ZLIB )
	midi? ( LGPL-2.1 ZLIB )
	mms? ( GPL-2 ZLIB )
	mono2stereo? ( ZLIB )
	mpg123? ( LGPL-2.1 ZLIB )
	musepack? ( BSD ZLIB )
	nullout? ( ZLIB )
	opus? ( ZLIB )
	oss? ( GPL-2 )
	playlist-browser? ( ZLIB )
	psf? ( BSD GPL-1 MAME ZLIB )
	pulseaudio? ( GPL-2 )
	shell-exec? ( GPL-2 )
	shn? ( shorten ZLIB )
	sid? ( GPL-2 )
	sndfile? ( GPL-2 LGPL-2 )
	tta? ( BSD ZLIB )
	vorbis? ( BSD ZLIB )
	vtx? ( GPL-2 ZLIB )
	wavpack? ( BSD )
	wma? ( GPL-2 LGPL-2 ZLIB )
	zip? ( ZLIB )
"
SLOT="0"
IUSE="
	+alsa +flac +gtk2 +hotkeys +m3u +mad +mp3 +sndfile +vorbis
	aac adplug alac cdda cdparanoia converter cover curl dts dumb equalizer
	ffmpeg gme gtk2 gtk3 imlib2 lastfm libav libnotify libsamplerate mac midi
	mms mono2stereo mpg123 musepack nls nullout opus oss playlist-browser psf
	pulseaudio replaygain-scanner sc68 shell-exec shn sid tta unity vtx wavpack
	wma zip
"
REQUIRED_USE="
	|| ( alsa oss nullout pulseaudio )
	cdparanoia? ( cdda )
	converter? ( || ( gtk2 gtk3 ) )
	cover? (
		|| ( gtk2 gtk3 )
		|| ( imlib2 curl )
	)
	ffmpeg? ( !libav )
	lastfm? ( curl )
	libav? ( !ffmpeg )
	mp3? ( || ( mad mpg123 ) )
	playlist-browser? ( || ( gtk2 gtk3 ) )
	shell-exec? ( || ( gtk2 gtk3 ) )
"

BDEPEND="
	virtual/pkgconfig
	nls? (
		dev-util/intltool
		virtual/libintl
	)
	mac? (
		x86? ( dev-lang/yasm )
		amd64? ( dev-lang/yasm )
	)
"
DEPEND="
	dev-libs/glib:2
	aac? ( media-libs/faad2 )
	alsa? ( media-libs/alsa-lib )
	alac? ( media-libs/faad2 )
	cdda? (
		dev-libs/libcdio:0=
		media-libs/libcddb
	)
	cdparanoia? ( dev-libs/libcdio-paranoia )
	cover? (
		media-libs/libpng:0=
		virtual/jpeg
		x11-libs/gdk-pixbuf:2[jpeg]
	)
	curl? ( net-misc/curl )
	elibc_musl? ( sys-libs/queue-standalone )
	ffmpeg? ( media-video/ffmpeg:0= )
	imlib2? ( media-libs/imlib2 )
	libav? ( media-video/libav:0= )
	flac? ( media-libs/flac )
	gme? ( sys-libs/zlib )
	gtk2? (
		dev-libs/atk
		dev-libs/jansson
		x11-libs/cairo
		x11-libs/gtk+:2
		x11-libs/pango
	)
	gtk3? (
		dev-libs/jansson
		x11-libs/gtk+:3
	)
	hotkeys? ( x11-libs/libX11 )
	libnotify? ( sys-apps/dbus )
	libsamplerate? ( media-libs/libsamplerate )
	mad? ( media-libs/libmad )
	midi? ( media-sound/timidity-freepats )
	mpg123? ( media-sound/mpg123 )
	opus? ( media-libs/opusfile )
	psf? ( sys-libs/zlib )
	pulseaudio? ( media-sound/pulseaudio )
	sndfile? ( media-libs/libsndfile )
	vorbis? (
		media-libs/libogg
		media-libs/libvorbis
	)
	wavpack? ( media-sound/wavpack )
	zip? ( dev-libs/libzip )
"
RDEPEND="${DEPEND}"

PLOCALES="
	be bg bn ca cs da de el en_GB es et eu fa fi fr gl he hr hu id it ja kk km
	lg lt lv nl pl pt pt_BR ro ru si_LK sk sl sr sr@latin sv te tr ug uk vi
	zh_CN zh_TW
"
PLOCALE_BACKUP="en_GB"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/DeadBeeF-Player/deadbeef.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/DeaDBeeF-Player/deadbeef/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

src_prepare() {
	# Fix the following automake error:
	#     Makefile.am:66: error: blank line following trailing backslash
	sed -i -e 's~\(COPYING\.LGPLv2\.1\)\\$~\1~' Makefile.am

	# Fix DeadBeeF 1.8.2-specific automake issues.
	[[ ${PV} == 1.8.2 ]] && eapply "${FILESDIR}/${P}-fix-gettext.patch"

	if use midi; then
		sed -i -e \
			's~/etc/timidity++/timidity-freepats.cfg\b~/usr/share/timidity/freepats/timidity.cfg~g' \
			"${S}/plugins/wildmidi/wildmidiplug.c" || die
	fi

	# If disabling Gnome Unity support, remove all Unity-specific lines from
	# DeaDBeef's input desktop file. Dismantled, this is:
	# * "/.../d", removing all lines matching this pattern.
	# * "/.../,$d", removing all lines beginning at the first line matching
	#   this pattern.
	if ! use unity; then
		sed -i \
			-e '/^\(Actions\|X-Ayatana-Desktop-Shortcuts\)=/d' \
			-e '/^\[\(Desktop Action Play\|Play Shortcut Group\)\]$/,$d' \
			deadbeef.desktop.in || die
	fi

	if [[ $(l10n_get_locales disabled) =~ 'ru' ]]; then
		sed -i -e '/\btranslation\/help\.ru\.txt\b/d' Makefile.am || die
		rm "${S}/translation/help.ru.txt" || die
	fi

	deadbeef_remove_disabled_locale() {
		sed -i -e '/\b'${1}'\b/d' po/LINGUAS || die
	}

	l10n_for_each_disabled_locale_do deadbeef_remove_disabled_locale

	eapply_user

	config_rpath_update "${S}/config.rpath"
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--disable-coreaudio
		--disable-portable
		--disable-static
		--docdir=/usr/share/doc/${PN}
		$(use_enable aac)
		$(use_enable adplug)
		$(use_enable alac)
		$(use_enable alsa)
		$(use_enable cdda)
		$(use_enable cdparanoia cdda-paranoia)
		$(use_enable converter)
		$(use_enable cover artwork)
		--enable-artwork-imlib2=$(usex cover $(usex imlib2))
		--enable-artwork-network=$(usex cover $(usex curl))
		$(use_enable curl vfs-curl)
		$(use_enable dts dca)
		$(use_enable dumb)
		$(use_enable equalizer supereq)
		$(use_enable ffmpeg)
		$(use_enable flac)
		$(use_enable gme)
		$(use_enable gtk2)
		$(use_enable gtk3)
		$(use_enable hotkeys)
		$(use_enable lastfm lfm)
		$(use_enable libav ffmpeg)
		$(use_enable libnotify notify)
		$(use_enable libsamplerate src)
		$(use_enable m3u)
		$(use_enable mac ffap)
		$(use_enable mad libmad)
		$(use_enable midi wildmidi)
		$(use_enable mms)
		$(use_enable mono2stereo)
		$(use_enable mpg123 libmpg123)
		$(use_enable musepack)
		$(use_enable nls)
		$(use_enable nullout)
		$(use_enable opus)
		$(use_enable oss)
		$(use_enable playlist-browser pltbrowser)
		$(use_enable psf)
		$(use_enable pulseaudio pulse)
		$(use_enable replaygain-scanner rgscanner)
		$(use_enable sc68)
		$(use_enable shell-exec shellexecui)
		$(use_enable shn)
		$(use_enable sid)
		$(use_enable sndfile)
		$(use_enable tta)
		$(use_enable vorbis)
		$(use_enable vtx)
		$(use_enable wavpack)
		$(use_enable wma)
		$(use_enable zip vfs-zip)
	)

	econf "${myeconfargs[@]}"
}

pkg_preinst() {
	if use gtk2 || use gtk3; then
		gnome2_icon_savelist
	fi
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update

	if use gtk2 || use gtk3; then
		xdg_icon_cache_update
	fi
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update

	if use gtk2 || use gtk3; then
		xdg_icon_cache_update
	fi
}
