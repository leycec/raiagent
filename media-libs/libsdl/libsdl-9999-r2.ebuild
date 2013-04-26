# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enable Bash strictness.
set -e

# SDL 2.0 officially distributes both autotools- and CMake-based builds. Due to
# all the usual autotools problems, the former essentially doesn't work. The
# latter, however, does. CMake it is!
inherit cmake-utils eutils flag-o-matic mercurial multilib toolchain-funcs

DESCRIPTION="Simple Direct Media Layer"
HOMEPAGE="http://www.libsdl.org"
EHG_REPO_URI="http://hg.libsdl.org/SDL"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64 ~x86"

#FIXME: Add "test".
# SDL 1.2 ebuilds prohibited unsafe CFLAGS unless "custom-flags" was enabled.
# This appears to have been overly judicious, as the query "How does one build
# an optimized SDL library?" at
# http://osdl.sourceforge.net/main/documentation/rendering/SDL-optimizing.html
# suggests. SDL supports at least a modicum of extreme optimization. If users
# enable unsafe CFLAGS, SDL breaking is the least of their concerns.
IUSE="
+audio feedback joystick +threads static-libs +video
3dnow altivec mmx sse sse2
alsa fusionsound nas oss pulseaudio
X xcursor xinerama xinput xrandr xscreensaver xvidmode
aqua directfb gles opengl tslib
"
REQUIRED_USE="
	feedback? ( joystick )
	alsa?        ( audio )
	fusionsound? ( audio )
	nas?         ( audio )
	oss?         ( audio )
	pulseaudio?  ( audio )
	aqua?     ( video )
	directfb? ( video )
	gles?     ( video )
	opengl?   ( video )
	tslib?    ( video )
	X?        ( video )
	xcursor?      ( X )
	xinerama?     ( X )
	xinput?       ( X )
	xrandr?       ( X )
	xscreensaver? ( X )
	xvidmode?     ( X )
"

#FIXME: Replace "gles" deps with "virtual/opengles", after hitting Portage.
RDEPEND="
	nas? (
		media-libs/nas
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXt
	)
	X? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXt
		x11-libs/libXrender
	)
	xcursor?  ( x11-libs/libXcursor )
	xinerama? ( x11-libs/libXinerama )
	xinput?   ( x11-libs/libXi )
	xrandr?   ( x11-libs/libXrandr )
	xvidmode? ( x11-libs/libXxf86vm )
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
	nas? (
		x11-proto/xextproto
		x11-proto/xproto
	)
	X? (
		x11-proto/xextproto
		x11-proto/xproto
		x11-proto/renderproto
	)
	xinerama? ( x11-proto/xineramaproto )
	xinput?   ( x11-proto/inputproto )
	xrandr?   ( x11-proto/randrproto )
	xrandr?   ( x11-proto/randrproto )
	xvidmode? ( x11-proto/xf86vidmodeproto )
	xscreensaver? ( x11-proto/scrnsaverproto )
"

CMAKE_MIN_VERSION=2.6  # ...if "CMakeLists.txt" is to be believed.

src_unpack() {
	[[ -d "${EHG_STORE_DIR}/${PN}" ]] ||
		einfo 'Cloning may take up to several minutes on slow connections.'
	mercurial_src_unpack
}

#FIXME: SDL2's current "CMakeLists.txt" file leaks LDFLAGS into pkg-config
#files, as confirmed by a QA notice. The offending CMake line appears to be:
#
#    target_link_libraries(SDL2 ${EXTRA_LIBS} ${EXTRA_LDFLAGS})
#
#Since target_link_libraries() is a core CMake function, it's unclear whether
#we can patch around this on our end. I'm surprised I haven't seen similar
#complaints from other CMake-dependent ebuilds, and thus suspect the issue *IS*
#our fault. Somehow, anyway...
src_prepare() {
	epatch "${FILESDIR}/${PV}-sdl2-config.in.patch"
}

src_configure() {
	# DirectFB can link against SDL, triggering a dependency loop. Link against
	# DirectFB only if it isn't currently being installed. (See issue #61592.)
	local use_directfb="-DVIDEO_DIRECTFB=ON"
	if use directfb; then
		echo 'int main(){}' > directfb-test.c
		$(tc-getCC) directfb-test.c -ldirectfb 2>/dev/null \
			&& use_directfb="-DVIDEO_DIRECTFB=OFF" \
			|| ewarn "Disabling DirectFB, since \"libdirectfb.so\" is broken."
		rm directfb-test.c
	fi

	# Required by cmake-utils_src_configure().
	mycmakeargs=(
		# Disable assertion tests.
		-DASSERTIONS=disabled
		# Avoid hard-coding RPATH entries into dynamically linked SDL libraries.
		-DRPATH=NO
		# Disable obsolete and/or inapplicable libraries.
		-DARTS=NO
		-DESD=NO
		${use_directfb}
		$(cmake-utils_use static-libs SDL_STATIC)
		$(cmake-utils_use audio       SDL_AUDIO)
		$(cmake-utils_use feedback    SDL_HAPTIC)
		$(cmake-utils_use joystick    SDL_JOYSTICK)
		$(cmake-utils_use video       SDL_VIDEO)
		$(cmake-utils_use threads SDL_THREADS)
		$(cmake-utils_use threads PTHREADS)
		$(cmake-utils_use threads PTHREADS_SEM)
		$(cmake-utils_use 3dnow)
		$(cmake-utils_use altivec)
		$(cmake-utils_use mmx)
		$(cmake-utils_use sse)
		$(cmake-utils_use sse SSEMATH)
		$(cmake-utils_use sse2)
		$(cmake-utils_use alsa)
		$(cmake-utils_use fusionsound)
		$(cmake-utils_use nas)
		$(cmake-utils_use oss)
		$(cmake-utils_use pulseaudio)
		$(cmake-utils_use tslib INPUT_TSLIB)
		$(cmake-utils_use X            VIDEO_X11)
		$(cmake-utils_use xcursor      VIDEO_X11_XCURSOR)
		$(cmake-utils_use xinerama     VIDEO_X11_XINERAMA)
		$(cmake-utils_use xinput       VIDEO_X11_XINPUT)
		$(cmake-utils_use xrandr       VIDEO_X11_XRANDR)
		$(cmake-utils_use xscreensaver VIDEO_X11_XSCRNSAVER)
		$(cmake-utils_use xvidmode     VIDEO_X11_XVM)
		$(cmake-utils_use aqua   VIDEO_COCOA)
		$(cmake-utils_use gles   VIDEO_OPENGLES)
		$(cmake-utils_use opengl VIDEO_OPENGL)
	)

	cmake-utils_src_configure
}

src_install() {
	# cmake-utils_src_install() installs all docs, except...
	cmake-utils_src_install
	for docfile in README* TODO BUGS CREDITS WhatsNew; do
		dodoc "${docfile}"
	done
}
