# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-emulation/dosbox/dosbox-0.74.ebuild,v 1.15 2013/04/02 15:35:59 mr_bones_ Exp $

# Since DOSBox SVN Daum significantly patches the official DOSBox, this ebuild
# inherits very little of the official "dosbox" ebuild. More's the pity.
EAPI=5

# Enforce bash strictness.
set -e

# List "games" last, as suggested by the "Gentoo Games Ebuild HOWTO."
inherit autotools eutils toolchain-funcs games

DESCRIPTION="DOS emulator (unofficial SVN-based Daum patchset maintained by ykhwong)"
HOMEPAGE="http://ykhwong.x-y.net"
SRC_URI="${P}.7z"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="alsa c++0x debug hardened opengl printer"

# DOSBox SVN Daum requires manual download. See pkg_nofetch() below. *sigh*
RESTRICT="fetch"

# DOSBox SVN Daum requires:
#
# * The newest released stable version of "libsdl" patched with Moe's
#   "openglhq" patch available from ykhwong's site. Since the official SDL 1.2
#   ebuilds provide no such patch, use the overlay-specific unofficial SDL 1.2
#   ebuild explicitly providing such patch. (Yes, this is insanity.)
# * The newest unreleased live version of "sdl-sound", unconditionally
#   supporting FLAC and Ogg Vorbis but *NOT* PhysFS.
RDEPEND="alsa? ( media-libs/alsa-lib )
	opengl? ( virtual/glu virtual/opengl )
	debug? ( sys-libs/ncurses )
	media-libs/libpng:0
	~media-libs/libsdl-1.2.9999[joystick,openglhq,video,X]
	media-libs/sdl-net
	~media-libs/sdl-sound-9999[flac,vorbis]"

#FIXME: We *REALLY* want a new "virtual/dosbox". Why? Because DOSBox frontends
#(e.g., DBGL) need to know that "dosbox-daum" is an acceptable DOSBox substitute.
#It's all certainly feasible, but a slight slice of a headache. Let's ignore the
#issue wholesale, for now.

# DOSBox SVN Daum supports additional libraries, all mandatory except
# Freetype. Make files should probably be patched so as to render *ALL*
# libraries optional, but it's hard to be bothered at the moment.
#
# "tbb" is Intel's Thread Building Blocks (TBB). Daum requires TBB for
# parallelizing high-quality image scaling under xBRZ. Since TBB currently only
# runs on x86 architecture (both 32- and 64-bit), this ebuild is unlikely to be
# very portable.
#
# OpenGLide is a Glide-to-OpenGL wrapper required by Daum but *NOT* listed as
# such by its documentation. Can we do better than that next time, ykhwong?
RDEPEND+="
	printer? ( media-libs/freetype )
	dev-cpp/tbb
	dev-games/physfs[zip]
	media-libs/flac
	media-libs/openglide
	media-sound/fluidsynth
	net-libs/libpcap"

# DOSBox SVN Daum is merely a patchset on DOSBox (albiet, a rather extensive
# patchset). Install directly over and hence conflict with DOSBox. Block!
RDEPEND+="
	!games-emulation/dosbox"

# DOSBox SVN Daum requires autotools reconfiguration of unspecified versions.
# (Yes, I'm not kidding.) Inheriting the "autotools" eclass above would also add
# such dependencies but in a version-dependent manner, as well as introducing
# spurious other issues -- including "repoman" complaints and a vast swath of
# warnings resembling:
#
#     am-wrapper: aclocal: warning: invalid WANT_AUTOMAKE 'latest'; ignoring.
DEPEND+="${RDEPEND}
	virtual/pkgconfig"
#sys-devel/autoconf
#sys-devel/automake

# Additional options to be passed to "automake" by eautoreconf(), derived from
# the contents of the "autogen.sh" script shipped with DOSBox SVN Daum.
AM_OPTS="--include-deps"

# DOSBox SVN Daum unzips into the current working directory.
S="${WORKDIR}"

# Totally lame, ykhwong. Mildly understandable, but totally lame.
pkg_nofetch() {
	einfo "To install DOSBox SVN Daum, manually download \"source.7z\" from"
	einfo "http://ykhwong.x-y.net/xe/?module=file&act=procFileDownload&file_srl=1346&sid=a25a3c7cdc5c2e99ee3d8821935bbd16"
	einfo "and move such file to \"${DISTDIR}/${SRC_URI}\"."
	einfo "Ensure such file is owned by \"portage:portage\" with permission bits 644!"
	einfo "Unfortunately, Javascript on ykhwong's site prohibits automated retrieval."
}

src_prepare() {
	# Patch DOSBox SVN Daum in the same manner as the official DOSBox ebuild.
	epatch "${FILESDIR}/dosbox-0.74-gcc46.patch"

	# Generate autotools scripts (e.g., "configure").
	eautoreconf
}

# See the "Compiling DOSBox" section of "linux.txt" for further details on
# Daum configuration and compilation.
#
# Do *NOT* set libraries and CFLAGS with the "flag-o-matic" eclass, as that
# results (for some innocuous reason) in the "configure" script failing with:
#
#     checking whether the C compiler works... no
#     configure: error: in `/var/tmp/portage/games-emulation/dosbox-daum-20130725/work':
#     configure: error: C compiler cannot create executables
#
# This ebuild has been a veritable cesspool of oddball mishaps from the get-go.
# What's one more?
src_configure() {
	# Libraries "libtbb" and "libFLAC" install no ".pc" files for "pkg-config"
	# and hence must be manually linked to. "gthread-2.0" does install such
	# files, however, and may be linked to with "pkg-config".
	LIBS+=" -ltbb -lFLAC $(pkg-config --libs gthread-2.0)"
	CPPFLAGS+=" $(pkg-config --cflags gthread-2.0)"

	# If enabling C++0x support, do so by passing such option *AND* an option
	# downgrading spurious "narrowing conversion" errors to warnings. (Even
	# Valve employs the latter fix, suggesting this is a "gcc" issue.)
	use c++0x && CXXFLAGS+=" -std=c++0x -fpermissive"

	# The "configure" script currently only supports a command-line option for
	# USE flag "printer". Shaders are Direct3D-specific and hence disabled.
	egamesconf \
		--disable-dependency-tracking \
		--disable-shaders \
		$(use_enable alsa alsa-midi) \
		$(use_enable !hardened dynamic-core) \
		$(use_enable !hardened dynamic-x86) \
		$(use_enable debug) \
		$(use_enable opengl) \
		$(use_enable printer)
}

src_install() {
	default
	dodoc AUTHORS ChangeLog NEWS README THANKS
	make_desktop_entry dosbox DOSBox /usr/share/pixmaps/dosbox.ico
	doicon src/dosbox.ico
	prepgamesdirs
}

#flag-o-matic 
#FIXME: We probably want to patch "Makefile.in" to do this. *shrug*
# Inherit the "autotools" eclass to add autotools dependencies run by the
# "autogen.sh" script.
#inherit autotools eutils games
# While
	# we could patch such script with additional support for USE flags
	#, wrap all
# changes specific to this ebuild with "#>>>>>>>" and "#<<<<<<<" guards "fluidsynth", "pcap", and "physfs", it seems simpler 
# Append rather than reset build-time dependencies to avoid overwriting the
# dependencies added by the "autotools" eclass, above.
#FIXME: Enabling this *USUALLY* (but not always, which is crazy in and of itself)
#induces obscure ebuild failure with message "[Errno 9] Bad file descriptor:".
#And... that's it. This is pretty clearly a Portage bug. As an initial fix, just
#try shifting such functionality to pkg_nofetch() above.

#pkg_pretend() {
#	# If the user requests C++11 support, ensure the current compiler supports
#	# such standard. (This conditional liberally lifted from "sci-physics/root".)
#	if use c++0x && [[ $(tc-getCXX) == *g++ ]] &&\
#		! version_is_at_least "4.7" "$(gcc-version)"; then
#		eerror ">=sys-devel/gcc-4.7.0 required for C++0x support"
#		die "Current gcc compiler does not support C++0x"
#	fi
#}

#append-libs -ltbb -lFLAC $(pkg-config --libs gthread-2.0)

	#FIXME: Reenable after worky.
#	append-cppflags $(pkg-config --cflags gthread-2.0)

	# Enable C++0x support by passing an (admittedly) g++-specific flag.
#	if use c++0x; then
#		append-cxxflags -std=c++11
#	fi

	#FIXME: Actually, it'd be far better to try calling eautoreconf() first.
	#Such function applies a wide array of benificial patches.

	# Convert DOS to Unix line endings in the "autogen.sh" script called below.
	# Failure to do so results in failure. (An aphorism is born every day.)
#sed -i 's~~~' autogen.sh

#sh autogen.sh
