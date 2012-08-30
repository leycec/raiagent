# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit eutils multilib

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
IUSE="+music"

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
	media-libs/libsdl:2
	media-libs/sdl-image:2
	media-libs/sdl-ttf:2
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
	sed -e "s~/usr/lib32~${ROOT}/$(get_abi_LIBDIR x86)~" \
		-e "s~/usr/include~${ROOT}/usr/include~" \
	    -e "s~/opt/SDL-2.0~${ROOT}/usr~" \
	    -i 'premake4.lua'
	sed -e "s~/opt/SDL-2.0/lib/~${ROOT}/$(get_libdir)~" \
	    -i 'build/te4core.lua'
}

src_configure() {
	# Generate the "Makefile".
	einfo 'Running "premake4 gmake"...'
	premake4 gmake || die '"premake4 gmake" failed'

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
	local tome4_home="${ROOT}/usr/share/tome4"
	insinto "${tome4_home}"
	doins -r bootstrap
	doins -r game
	exeinto "${tome4_home}"
	doexe t-engine

	# The "t-engine" executable expects to be executed from "${tome4_home}".
	# Install "tome4", a Bourne shell script enforcing this.
	cat <<EOF > tome4
#!/bin/sh
cd "${tome4_home}"
./t-engine
EOF
	dobin tome4
}

#FIXME: Great post on te4 forums concerning building recent versions:
#
#  http://forums.te4.org/viewtopic.php?p=114539#p114539
#
#Probably the best resource as of yet. It looks like one of the keys is sedding
#LuA files bundled with the source. Oh, and here's another one:
#
#  http://forums.te4.org/viewtopic.php?f=36&t=28096
#
#O.K.; so, it looks like ToME4 probably won't build. At least, no one seems to
#have got a recent build working. Actually, "greycat" has. Bless his helpful
#commentary! This may just be possible.

#inherit cmake-utils eutils flag-o-matic multilib toolchain-funcs
# Embedding of USE flags in "SRC_URI" is effectively useless under EAPI 4.
# Ideally, we want to permit the user to customize which distfile to retrieve
# via the "music" USE flag, like so:
#
#   SRC_URI="
#	   music? ( ${HOMEPAGE}/dl/t-engine/${MY_P}.tar.bz2 )
#	  !music? ( ${HOMEPAGE}/dl/t-engine/${MY_P}-nomusic.tar.bz2 )"
#   IUSE="music"
#
# Naturally, that doesn't work. So, we currently force music on everyone.
	# Since
	# these expansions always follow expansions of ${CPPFLAGS} and themselves
	# are always followed by hardcoded CPPFLAGS, eliminate both with one fell
	# swoop by forcing CFLAGS 
	# truncating all text following expansions of ${CPPFLAGS}. Also,
	# let Portage decide whether to strip binaries by excising "-s".
#	sed -e 's~\($(CPPFLAGS)\).*~\1~' \

#-e 'CPPFLAGS  += -MMD -MP $(DEFINES) $(INCLUDES)'
#-e 's~CPPFLAGS\s*+=~\1~' \
#-e 's~$(ARCH) ~~' \
#SRC_URI="${HOMEPAGE}/dl/t-engine/${MY_P}.tar.bz2"
#SRC_URI="http://te4.org/dl/t-engine/${MY_P}.tar.bz2"
#SRC_URI="http://te4.org/dl/t-engine/t-engine4-src-1.0.0beta42.tar.bz2"
#RESTRICT="mirror"
#IUSE=""
#RESTRICT="mirror"
#	dev-lang/lua
#	media-libs/freetype:2
#	media-libs/libogg
#	media-libs/libvorbis
#	media-libs/mesa
#	media-libs/smpeg
#	media-libs/tiff
#	virtual/jpeg
#	media-libs/sdl-gfx
#	media-libs/sdl-mixer
#	media-libs/sdl-net
#	media-libs/libmikmod

#src_compile() {
#	    emake
#}
