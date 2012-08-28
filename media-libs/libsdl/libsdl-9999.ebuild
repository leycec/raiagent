# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
inherit autotools-utils eutils flag-o-matic mercurial multilib toolchain-funcs

DESCRIPTION="Simple Direct Media Layer"
HOMEPAGE="http://www.libsdl.org"
EHG_REPO_URI="http://hg.libsdl.org/SDL"

#FIXME: Add "test" to IUSE.
LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64"
IUSE="
+audio +video joystick threads
3dnow altivec mmx sse sse2
alsa fusionsound nas oss pulseaudio
X xcursor xinerama xinput xrandr +xrender xscreensaver xv
aqua directfb gles opengl tslib 
custom-cflags static-libs"

#FIXME: Replace "gles" deps with "virtual/opengles" after hitting Portage.
RDEPEND="
	X? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXt
	)
	nas? (
		media-libs/nas
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXt
	)
	xcursor?  ( x11-libs/libXcursor )
	xinerama? ( x11-libs/libXinerama )
	xinput?   ( x11-libs/libXi )
	xrandr?   ( x11-libs/libXrandr )
	xrender?  ( x11-libs/libXrender )
	xv?       (	x11-libs/libXv )
	xscreensaver? ( x11-libs/libXScrnSaver )
	alsa? ( media-libs/alsa-lib )
	fusionsound? ( >=media-libs/FusionSound-1.1.1 )
	pulseaudio? ( >=media-sound/pulseaudio-0.9 )
	directfb? ( >=dev-libs/DirectFB-1.0.0 )
	gles? ( || ( media-libs/mesa[gles2] media-libs/mesa[gles] ) )
	opengl? ( virtual/opengl )
	tslib? ( x11-libs/tslib )
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	X?   ( x11-proto/xextproto x11-proto/xproto )
	nas? ( x11-proto/xextproto x11-proto/xproto )
	xinerama? ( x11-proto/xineramaproto )
	xinput?   ( x11-proto/inputproto )
	xrandr?   ( x11-proto/randrproto )
	xrender?  ( x11-proto/renderproto )
	xv?       ( x11-proto/videoproto )
	xscreensaver? ( x11-proto/scrnsaverproto )
"

PATCHES=(
	"${FILESDIR}/${PV}-sdl2-config.in.patch"
 	"${FILESDIR}/${PV}-ac_check_define.m4.patch"
)

# Live sources require regeneration of "configure" from "configure.in".
AUTOTOOLS_AUTORECONF=1

# SDL supplies no "Makefile.am". Disable "automake" use.
WANT_AUTOMAKE='none'

# SDL supplies an m4 directory. (Praise be to the Nordic gods.)
AT_M4DIR="acinclude"

pkg_setup() {
	if use custom-cflags; then
		ewarn 'Compiling under possibly unsafe custom CFLAGS.'
		ewarn 'Consider disabling or removing "custom-cflags".'
		epause 8
	fi
}

src_unpack() {
	# Clone or update SDL, as required.
	[[ -d "${EHG_STORE_DIR}/${PN}" ]] ||
		einfo 'Cloning may take up to several minutes on slow connections.'
	mercurial_src_unpack

	# eaclocal() fails to identify the "aclocal.m4" SDL ships as pre-generated
	# and hence requiring regeneration. Force the issue by deleting it.
 	rm "${S}/aclocal.m4"
}

src_configure() {
	# Strip unsafe CFLAGS unless the user bravely demands we not.
	use custom-cflags || strip-flags

	# DirectFB can link against SDL, triggering a dependency loop. Link against
	# DirectFB only if it isn't broken. (See issue #61592.)
	local enable_directfb="--disable-video-directfb"
	if use directfb; then
		echo 'int main(){}' > directfb-test.c
		$(tc-getCC) directfb-test.c -ldirectfb 2>/dev/null \
			&& enable_directfb="--enable-video-directfb" \
			|| ewarn "Disabling DirectFB, since \"libdirectfb.so\" is broken."
		rm directfb-test.c
	fi

	# Required by autotools-utils_src_configure(), which handles "static-libs".
	local myeconfargs=(
		# Avoid hard-coding RPATH entries into dynamically linked SDL libraries.
		--disable-rpath
		# Avoid the obsolete aRts and ESD and inapplicable DirectX libraries.
		--disable-arts
		--disable-esd
 		${enable_directfb}
		$(use_enable audio)
		$(use_enable joystick)
		$(use_enable threads)
		$(use_enable video)
		$(use_enable 3dnow)
		$(use_enable altivec)
		$(use_enable mmx)
		$(use_enable sse)
		$(use_enable sse ssemath)
		$(use_enable sse2)
		$(use_enable alsa)
		$(use_enable fusionsound)
		$(use_enable nas)
		$(use_enable oss)
		$(use_enable pulseaudio)
		$(use_with   X x)
		$(use_enable X            video-x11)
		$(use_enable xinerama     video-x11-xinerama)
		$(use_enable xrandr       video-x11-xrandr)
		$(use_enable xscreensaver video-x11-scrnsaver)
		$(use_enable aqua     video-cocoa)
		$(use_enable gles     video-opengles)
		$(use_enable opengl   video-opengl)
		$(use_enable tslib input-tslib)
	)

	# Vicariously calls econf().
	autotools-utils_src_configure
}

src_install() {
	# Let autotools-utils_src_install() install all docs, except...
	autotools-utils_src_install
	dodoc WhatsNew
}
