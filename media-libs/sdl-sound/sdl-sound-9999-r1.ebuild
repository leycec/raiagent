# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enable Bash strictness.
set -e

inherit autotools eutils mercurial

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="A library that handles the decoding of sound file formats"
HOMEPAGE="http://icculus.org/SDL_sound"
EHG_REPO_URI="https://hg.icculus.org/icculus/SDL_sound"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS=""
IUSE="flac midi mikmod modplug mp3 mpeg physfs speex static-libs vorbis wav"

RDEPEND+="
	>=media-libs/libsdl-1.2
	flac?    ( media-libs/flac )
	mikmod?  ( >=media-libs/libmikmod-3.1.9 )
	modplug? ( media-libs/libmodplug )
	mp3?     ( media-sound/mpg123 )
	physfs?  ( dev-games/physfs )
	speex?   ( media-libs/speex media-libs/libogg )
	vorbis?  ( >=media-libs/libvorbis-1.0_beta4 )
"
DEPEND+="${RDEPEND}
	virtual/pkgconfig
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# Dynamically patch (i.e., with "sed") all files statically patched (i.e.,
	# with epatch()) by "sdl-sound-1.0.3.ebuild". Due to minute differences
	# between SDL_sound v1.0.3 and live sources, static patches fail to apply
	# to SDL_sound live sources. Indeed, given the simplicity of such changes,
	# it's unclear why static patches were chosen in the first place. Ideally,
	# dynamic patching should prove more robust in the face of future commits to
	# the SDL_sound live repository.
	sed -i -e 's~\(libSDL_sound_la_LIBADD =\)~\1 -lm~' Makefile.am
	sed -i -e 's~AM\(_CONFIG_HEADER(config.h)\)~AC\1~' configure.in

	# Regenerate the "configure.in" and "Makefile.in" scripts.
	mv configure.in configure.ac
	eautoreconf
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable flac) \
		$(use_enable mikmod) \
		$(use_enable midi) \
		$(use_enable modplug) \
		$(use_enable mp3 mpg123) \
		$(use_enable speex) \
		$(use_enable static-libs static) \
		$(use_enable physfs) \
		$(use_enable vorbis ogg) \
		$(use_enable wav)
}

src_install() {
	default
	dodoc CHANGELOG.txt CREDITS.txt README.txt TODO.txt
	use static-libs || prune_libtool_files --all
}
