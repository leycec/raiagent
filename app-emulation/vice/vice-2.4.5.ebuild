# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vice/vice-2.4.ebuild,v 1.10 2013/06/04 20:41:32 mr_bones_ Exp $

EAPI=5

# Enable Bash strictness.
set -e

inherit autotools eutils toolchain-funcs games

DESCRIPTION="The Versatile Commodore 8-bit Emulator"
HOMEPAGE="http://vice-emu.sourceforge.net/"
SRC_URI="mirror://sourceforge/vice-emu/development-releases/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="Xaw3d alsa cairo gnome gtk3 midi nls opengl pic png readline sdl sdlui sse ipv6 memmap ethernet oss zlib X gif jpeg xv dga xrandr ffmpeg lame pulseaudio"
REQUIRED_USE="
	gtk3?   ( gnome )
	cairo?  ( gnome !gtk3 )
	opengl? ( gnome !gtk3 )
	sdlui?  ( sdl )"

RDEPEND="
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXpm
	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libXt
	x11-libs/libXxf86vm
	x11-apps/xset
	Xaw3d? ( x11-libs/libXaw3d )
	!Xaw3d? ( !gnome? ( x11-libs/libXaw ) )
	alsa? ( media-libs/alsa-lib )
	gnome? (
		x11-libs/vte:0
		dev-libs/atk
		x11-libs/pango
		 gtk3? ( x11-libs/gtk+:3 )
		!gtk3? (
			x11-libs/gtk+:2
			cairo? ( x11-libs/cairo )
			opengl? ( x11-libs/gtkglext )
		)
	)
	lame? ( media-sound/lame )
	ffmpeg? ( virtual/ffmpeg )
	ethernet? (
	    >=net-libs/libpcap-0.9.8
	    >=net-libs/libnet-1.1.2.1
	)
	nls? ( virtual/libintl )
	png? ( media-libs/libpng:0 )
	readline? ( sys-libs/readline )
	sdl? ( media-libs/libsdl )
	gif? ( media-libs/giflib )
	jpeg? ( virtual/jpeg )
	xv? ( x11-libs/libXv )
	dga? ( x11-libs/libXxf86dga )
	xrandr? ( x11-libs/libXrandr )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	x11-apps/bdftopcf
	x11-apps/mkfontdir
	x11-proto/xproto
	x11-proto/xf86vidmodeproto
	x11-proto/xextproto
	dga? ( x11-proto/xf86dgaproto )
	xv? ( x11-proto/videoproto )
	nls? ( sys-devel/gettext )"

src_prepare() {
	# This version of VICE already incorporates the Gentoo-specific patches for
	# VICE version 2.4 -- excluding "vice-2.4-autotools.patch", which fails to
	# cleanly apply and hence is applied via "sed" below.
	sed -i \
		-e "s:/usr/local/lib/VICE:${GAMES_DATADIR}/${PN}:" \
		man/vice.1 \
		$(grep -rl --exclude="*texi" /usr/local/lib doc)

	# This version of VICE ships "configure.ac" rather than "configure.in".
	# To avoid errors on empty if conditionals, replace rather than deleting
	# lines containing "VICE_ARG_LIST_CHECK" with the noop operator ":".
	sed -i \
		-e 's:AM_CONFIG_HEADER\((src/config.h)\):AC_CONFIG_HEADERS\1:' \
		-e '/VICE_ARG_LIST_CHECK/c:' \
		-e "/VICEDIR=/s:=.*:=\"${GAMES_DATADIR}/${PN}\";:" \
		configure.ac
	sed -i \
		-e "s:\(#define LIBDIR \).*:\1\"${GAMES_DATADIR}/${PN}\":" \
		-e "s:\(#define DOCDIR \).*:\1\"/usr/share/doc/${PF}\":" \
		src/arch/unix/archdep.h \
		src/arch/sdl/archdep_unix.h
	AT_NO_RECURSIVE=1 eautoreconf
}

src_configure() {
	# don't try to actually run fc-cache (bug #280976)
	FCCACHE=/bin/true \
	PKG_CONFIG=$(tc-getPKG_CONFIG) \
	egamesconf \
		--enable-fullscreen \
		--enable-inline \
		--enable-parsid \
		--enable-textfield \
		--with-resid \
		--disable-bundle \
		--disable-debug \
		--disable-debug-code \
		--disable-dingoo \
		--disable-dingux \
		--disable-editline \
		--disable-embedded \
		--disable-hidmgr \
		--disable-hidutils \
		--disable-quicktime \
		--disable-realdevice \
		--disable-rs232 \
		--without-arts \
		--without-cocoa \
		--without-midas \
		--without-picasso96 \
		$(use pic || echo '--enable-no-pic') \
		$(use gnome && use !gtk3 && echo '--enable-gnomeui') \
		$(use_enable gtk3 gnomeui3) \
		$(use_enable ffmpeg) \
		$(use_enable ipv6) \
		$(use_enable lame) \
		$(use_enable midi) \
		$(use_enable nls) \
		$(use_enable sdlui) \
		$(use_enable sse) \
		$(use_with Xaw3d xaw3d) \
		$(use_with alsa) \
		$(use_with pulseaudio pulse) \
		$(use_with png) \
		$(use_with opengl uithreads ) \
		$(use_with readline) \
		$(use_with sdl sdlsound) \
		$(use oss || echo --without-oss) \
		$(use_enable memmap) \
		$(use_enable ethernet) \
		$(use_with zlib) \
		$(use_with X x)
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog FEEDBACK README
	prepgamesdirs
}
