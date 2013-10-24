# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

# List "games" last, as suggested by the "Gentoo Games Ebuild HOWTO."
inherit eutils multilib pax-utils games

MY_PN="t-engine4"
MY_PV="${PV/_/}"
MY_PV="${MY_PV/rc/RC}"
MY_P="${MY_PN}-src-${MY_PV}"

DESCRIPTION="Topdown tactical RPG roguelike game and game engine"
HOMEPAGE="http://te4.org"
SRC_URI="
	 music? ( ${HOMEPAGE}/dl/t-engine/${MY_P}.tar.bz2 )
	!music? ( ${HOMEPAGE}/dl/t-engine/${MY_P}-nomusic.tar.bz2 )
"

LICENSE="GPL-3 shockbolt-tileset Apache-2.0 BitstreamVera"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+jit +music"

# See the "links" array under "linux" in "build/te4core.lua" for dependencies.
# "virtual/libc" provides the "libdl", "libpthread", and "libm" libraries.
#
# ToME4 bundles additional dependencies with its source tarball (e.g., "bzip2"),
# usually patched in a ToME4-specific manner and hence *NOT* safely replaceable
# with system-wide dependencies. For safety, avoid molesting such dependencies.
#
# Thanks to Gentoo developer hasufell for improved dependencies.
RDEPEND="
	media-libs/glew:=
	media-libs/libpng:0=
	media-libs/libsdl2:=[X,opengl,video]
	media-libs/libvorbis:=
	media-libs/openal:=
	media-libs/sdl2-image:=[png]
	media-libs/sdl2-ttf:=[X]
	virtual/glu
	virtual/libc
	virtual/opengl
"
DEPEND="${RDEPEND}
	>=dev-util/premake-4.3:4
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}/1.0.4-optimization.patch"

	# ToME4 uses a hand-rolled Lua-based build system. As expected, it's rather
	# inflexible and requires sed-driven patches. Order is significant, here.
	sed -i \
		-e "s~/usr/lib32~${EPREFIX}/$(get_abi_LIBDIR x86)~" \
	    -e "s~/usr/include~${EPREFIX}/usr/include~" \
	    -e "s~/opt/SDL-2.0~${EPREFIX}/usr~" \
	    'premake4.lua'
	sed -i \
		-e "s~/opt/SDL-2.0/lib/~${EPREFIX}/$(get_libdir)~" \
	    'build/te4core.lua'
}

src_configure() {
	# Options to be passed to "premake4".
	local premake_options="--lua=$(usex jit "jit2" "default")"

	# Generate a "Makefile" with "premake4".
	einfo "Running \"premake4 ${premake_options} gmake\"..."
	premake4 ${premake_options} gmake

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
	#
	# Also avoid implicitly stripping debug symbols from binaries.
	sed -i \
		-e 's~\(CFLAGS\s*+= \).*~\1-MMD -MP $(DEFINES) $(INCLUDES)~' \
		-e 's~\(CXXFLAGS\s*+= \).*~\1-MMD -MP $(DEFINES) $(INCLUDES)~' \
		-e '/LDFLAGS/s~-s~~' \
		-e 's~$(ARCH) ~~' \
		build/*.make

	# Respect ${LDFLAGS}. Thanks to Gentoo developer hasufell, again.
    sed -i \
		-e 's~^[ \t]*LINKCMD.*$~LINKCMD = $(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS) $(RESOURCES) $(LDFLAGS) $(LIBS)~' \
        build/{buildvm,minilua,TEngine}.make
}

src_compile() {
	# Though "premake4" documentation insists it defaults to release builds,
	# ToME4 defaults to debug builds. Enforce sanity.
	#
	# Prohibit parallel make, currently known to be broken.
	config='release' emake -j1 verbose=1
}

# Oddly, "premake4" generates no "install" Makefile target. Do so by hand.
src_install() {
	# Directory to install ToME4 to.
	local tome4_home="${GAMES_DATADIR}/${PN}"

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
	dodoc CONTRIBUTING CREDITS

	# Install ToME4.
	insinto "${tome4_home}"
	doins -r bootstrap game
	exeinto "${tome4_home}"
	doexe t-engine

	# Force game-specific user and group permissions.
	prepgamesdirs
}
