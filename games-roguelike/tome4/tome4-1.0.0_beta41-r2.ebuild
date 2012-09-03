# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit eutils multilib pax-utils

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
	media-libs/libsdl:2[X]
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
	premake4 "${premake_options[@]}" gmake || die '"premake4 gmake" failed'

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
}

src_install() {
	dodoc CONTRIBUTING COPYING-TILES CREDITS

	# Oddly, "premake4" generates no "install" Makefile target. Do so by hand.
	local tome4_home="${EROOT}/usr/share/tome4"
	insinto "${tome4_home}"
	doins -r bootstrap
	doins -r game
	exeinto "${tome4_home}"
	doexe t-engine

	# If enabling a Lua JIT interpreter, disable MPROTECT under PaX-hardened
	# kernels. (All Lua JIT interpreters execute in-memory code and hence cause
	# "Segmentation fault" errors under MPROTECT.)
	use jit && pax-mark m "${ED}/${tome4_home}/t-engine"

	# The "t-engine" executable expects to be executed from "${tome4_home}".
	# Install "tome4", a Bourne shell script enforcing this.
	cat <<EOF > tome4
#!/bin/sh
cd "${tome4_home}"
./t-engine
EOF
	dobin tome4
}
