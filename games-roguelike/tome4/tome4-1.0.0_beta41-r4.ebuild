# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

#FIXME: Replicate to the SDL ebuilds.
# Enforce Bash strictness.
set -e

# List "games" last, as suggested by the "Gentoo Games Ebuild HOWTO."
inherit eutils multilib pax-utils games

# ToME4 uses oddball version specifiers. Portage permits only strict version
# specifiers. The result is a classical clusterf... well, you get the idea.
MY_PN="t-engine4"
MY_P="${MY_PN}-src-${PV/_/}"
DESCRIPTION="Topdown tactical RPG roguelike game and game engine"
HOMEPAGE="http://te4.org"
SRC_URI="
	 music? ( ${HOMEPAGE}/dl/t-engine/${MY_P}.tar.bz2 )
	!music? ( ${HOMEPAGE}/dl/t-engine/${MY_P}-nomusic.tar.bz2 )
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+jit +music"

#FIXME: ToME4 bundles *EVERYTHING* except SDL 2.0. While convenient, this does
#substantially complicate a Gentoo-centric build process. Let's take it one
#bundled library at a time, starting with "src/bzip2". Actually, forget about
#it; ToME4 is sufficiently fragile and in flux, at the moment, that any
#momentarily successful unbundling would likely be undone by the next beta.
#ToME4 supplies it's own patches with bundled dependencies, and it's not clear
#that they can be reasonably unbundled without extreme breakage. Also, it's
#quite likely ToME4 requires additional USE flags on "libsdl".

# See the "links" array under "linux" in "build/te4core.lua" for dependencies.
# ("virtual/libc" provides the "libdl", "libpthread", and "libm" libraries.)
RDEPEND="
	media-libs/glew
	media-libs/libpng
	media-libs/libvorbis
	media-libs/openal
	media-libs/libsdl:2[X,opengl]
	media-libs/sdl-image:2[png]
	media-libs/sdl-ttf:2[X]
	virtual/libc
"
DEPEND="${RDEPEND}
	>=dev-util/premake-4.3
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}/${PV}-physfs.patch"

	# ToME4 uses a hand-rolled Lua-based build system. As expected, it's rather
	# inflexible and requires sed-driven patches. Order is significant, here.
	sed -e "s~/usr/lib32~${EPREFIX}/$(get_abi_LIBDIR x86)~" \
	    -e "s~/usr/include~${EPREFIX}/usr/include~" \
	    -e "s~/opt/SDL-2.0~${EPREFIX}/usr~" \
	    -i 'premake4.lua'
#		-i 'premake4.lua' || die 'sed "premake4.lua" failed'
	sed -e "s~/opt/SDL-2.0/lib/~${EPREFIX}/$(get_libdir)~" \
	    -i 'build/te4core.lua'
}

src_configure() {
	# Options to be passed to "premake4".
	local premake_options=()
	if use jit
	then premake_options+=( --lua=jit2 )
	else premake_options+=( --lua=default )
	fi

	# Generate a "Makefile" with "premake4".
	einfo "Running \"premake4 ${premake_options[@]} gmake\"..."
	premake4 "${premake_options[@]}" gmake
#	premake4 "${premake_options[@]}" gmake || die '"premake4 gmake" failed'

	# "premake4" attempts to force expansion of environment variable ${ARCH}
	# into "gcc" calls. Since Gentoo already sets ${ARCH} (e.g., to "amd64") and
	# since no file named ${ARCH} exists (or if it exists should certainly not
	# be compiled), src_compile() fails with:
	#
	#   gcc: amd64: No such file or directory
	#
	# To circumvent this, excise all expansions of ${ARCH} from makefiles as
	# well as hardcoded ${CFLAGS}. Curiously, the makefiles "premake4" makes
	# append ${CPPFLAGS} (i.e., C preprocessor flags) onto ${CXXFLAGS} (i.e.,
	# C++ compiler flags). This is rarely safe. Forbid all such issues by
	# appending only sane ToME4-specific flags (e.g., "-MMD") onto ${CFLAGS} and
	# ${CPPFLAGS}. Arguably, one or all such issues constitute ToME4 bugs.
	sed -e 's~\(CFLAGS\s*+= \).*~\1-MMD -MP $(DEFINES) $(INCLUDES)~' \
		-e 's~\(CXXFLAGS\s*+= \).*~\1-MMD -MP $(DEFINES) $(INCLUDES)~' \
		-e 's~\(LDFLAGS\s*+=\) -s~\1~' \
		-i build/*.make

	# The declaration of "LINKCMD" in "TEngine.make" attempts to expand ${ARCH}.
	sed -ie 's~$(ARCH) ~~' build/TEngine.make
}

src_compile() {
	# Though "premake4" documentation insists it defaults to release builds,
	# ToME4 defaults to debug builds. Enforce sanity.
	config='release' emake
#	emake
}

# Oddly, "premake4" generates no "install" Makefile target. Do so by hand.
src_install() {
	# Directory to install ToME4 to.
	local tome4_home="${GAMES_PREFIX}/${PN}"

	#FIXME: Ideally, "pax-mark m" should be prefixed with "use jit &&".
	#Disabling Lua JIT should permit PaX-hardened MPROTECT restrictions. It
	#doesn't, and it's not entirely clear why. Globally disable such
	#restrictions for now, until we get a better handle on what ToME4 is doing.
	# If enabling a Lua JIT interpreter, disable MPROTECT under PaX-hardened
	# kernels. (All Lua JIT interpreters execute in-memory code and hence cause
	# "Segmentation fault" errors under MPROTECT.)
	pax-mark m t-engine

	# The "t-engine" executable expects to be executed from its home directory.
	# Unfortunately, this does not seem to be readily patchable.
	games_make_wrapper "${PN}" ./t-engine "${tome4_home}"

	# Install documentation.
	dodoc CONTRIBUTING COPYING-TILES CREDITS

	# Install ToME4.
	insinto "${tome4_home}"
	doins -r bootstrap
	doins -r game
	exeinto "${tome4_home}"
	doexe t-engine

	# Force games-specific user and group permissions.
	prepgamesdirs
}
