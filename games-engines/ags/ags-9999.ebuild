# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

# The open-source AGS runtime engine has yet to release an official version.
EGIT_REPO_URI="git://github.com/adventuregamestudio/ags.git"
EGIT_BRANCH="main"

inherit eutils git-r3

DESCRIPTION="Adventure Game Studio (AGS) runtime engine"
HOMEPAGE="https://github.com/adventuregamestudio/ags"

#FIXME: Add "html" USE flag. When enabled, run
#"Manual/compile_documentation_unix.sh" in the src_compile() phase to compile
#HTML documentation into the "Manual/html", which src_install() should then
#manually install.
LICENSE="Artistic-2"
SLOT="0"
KEYWORDS=""
IUSE="+midi"

RDEPEND="
	>=media-libs/allegro-4.2.2
	>=media-libs/dumb-0.9.3
	>=media-libs/aldumb-0.9.3
	>=media-libs/freetype-2.4.9
	>=media-libs/libogg-1.3.0
	>=media-libs/libtheora-1.1.1
	>=media-libs/libvorbis-1.3.2
	midi? ( media-sound/timidity-eawpatches )
"

# The AGS Makefile explicitly calls "gcc". *wag eyebrows evocatively and shrug*
DEPEND="${RDEPEND}
	sys-devel/gcc
"

# Copy the cloned git repository to the expected directory but actually work in
# such directory's "Engine" subdirectory, containing Makefiles and the codebase.
EGIT_SOURCEDIR="${WORKDIR}/${P}"
S="${EGIT_SOURCEDIR}/Engine"

# MIDI-specific installation paths.
AGS_INSTALL_DIR="usr/share/${PN}"
AGS_PATCHES_DAT="${AGS_INSTALL_DIR}/patches.dat"

src_prepare() {
	# The open-source AGS runtime engine bundles numerous port-specific Makefiles.
	# Patch and move the Linux-specific Makefile to "Makefile".
	epatch "${FILESDIR}/${PV}-Makefile.linux.patch"
	mv "Makefile.linux" "Makefile"
}

src_install() {
	default_src_install

	#FIXME: The "allegro" ebuild should probably have a "midi" USE flag to
	#enable such behavior. This is, arguably, outside the scope of AGS.
	# If enabling MIDI music, compile Eric A. Welsh's timidity GUS patches into
	# an Allegro-specific "patches.dat" file. For further gory details, see:
	#     http://alleg.sourceforge.net/digmid.html
	if use midi; then
		local src_patches_cfg="${ROOT}usr/share/timidity/eawpatches/default.cfg"
		einfo "Converting Eric A. Welsh's GUS patches to \"${ROOT}${AGS_PATCHES_DAT}\"..."
		dodir "/${AGS_INSTALL_DIR}"
		pat2dat -o "${D}${AGS_PATCHES_DAT}" "${src_patches_cfg}" -8
	fi
}

pkg_postinst() {
	elog 'Run AGS games by running "ags" with game directories or executables: e.g.,'
	elog '    ags /path/to/game/'
	elog '    ags /path/to/game/executable.exe'

	if use midi; then
		elog
		elog "Enable MIDI music in AGS games by copying \"${ROOT}${AGS_PATCHES_DAT}\""
		elog "to either your home directory, the same directory as your game, or"
		elog "\"${ROOT}usr/share/allegro\"."
	fi

	elog
	elog 'For games that fail to start, note AGS uses configuration file "acsetup.cfg"'
	elog 'in game directories if found. This file occasionally causes issues; try'
	elog 'deleting when in doubt.'
}

	# Strip hard-coded CFLAGS and CXXFLAGS.
#sed -e 's~^\(CFLAGS = \).*\(-D.*\)$~COMMON_FLAGS = $(addprefix -I,$(INCDIR) \2' \
#    -e '/^CXXFLAGS =.*$/d' \
#	-e 's~^\(CX?X?FLAGS\s*:= \).*$~\1 $(COMMON_FLAGS)' \
#	-e '$(addprefix -I,$(INCDIR)'
