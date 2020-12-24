# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#FIXME: Note that AGS has been significantly refactored to now require both
#Cmake and SDL2 in place of make and the obsolete aldumb + Allegro backend.
#Since this refactoring has yet to land in a stable release, we preserve the
#current obsolete approach for now. Note that we *MUST* absolutely remove the
#"media-lib/aldumb" package we currently provide in this repository as soon as
#possible, as that package has multiple unresolved CVEs filed against it and is
#no longer in active development. See also:
#    https://github.com/adventuregamestudio/ags/pull/1137

inherit eutils readme.gentoo-r1

DESCRIPTION="Adventure Game Studio (AGS) runtime engine"
HOMEPAGE="
	http://www.adventuregamestudio.co.uk
	https://github.com/adventuregamestudio/ags"

#FIXME: Add "html" USE flag. When enabled, run
#"Manual/compile_documentation_unix.sh" in the src_compile() phase to compile
#HTML documentation into the "Manual/html" subdirectory, which the src_install()
#phase should then manually install.
LICENSE="Artistic-2"
SLOT="0"
KEYWORDS=""
IUSE="+midi tremor"

BDEPEND="sys-devel/gcc[cxx]"
RDEPEND="
	>=media-libs/allegro-4.2.2:0
	>=media-libs/dumb-0.9.3[allegro]
	>=media-libs/freetype-2.4.9:2
	>=media-libs/libogg-1.3.0
	>=media-libs/libtheora-1.1.1
	>=x11-libs/libXext-1.3.3
	>=x11-libs/libXxf86vm-1.1.4
	midi? ( media-sound/timidity-eawpatches )
	tremor? ( media-libs/tremor )
	!tremor? ( >=media-libs/libvorbis-1.3.2 )
"
DEPEND="${RDEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/adventuregamestudio/ags"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PV="v.${PV}"

	SRC_URI="https://github.com/adventuregamestudio/ags/archive/${MY_PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

# MIDI-specific installation paths.
AGS_INSTALL_DIR="/usr/share/${PN}"
AGS_PATCHES_DAT="${AGS_INSTALL_DIR}/patches.dat"

src_prepare() {
	# Strip hard-coded ${CFLAGS}.
	sed -i -e 's~-O2 -g~~' Engine/Makefile-defs.linux || die '"sed" failed.'

	# Force AGS to link against shared rather than static libraries for the
	# "media-libs/dumb" dependency. They currently appear to force the latter
	# for conformance with Debian, which is understandable albeit frustrating.
	# Since this will all go away when upstream stabilizes SDL2 support, this
	# absolutely is *NOT* worth reporting to upstream.
	sed -i -e 's~^LIBS +=.*dumb.*$~LIBS += -laldmb -ldumb~' \
		Engine/Makefile-defs.linux || die '"sed" failed.'

	# Apply user-specific patches *AFTER* applying requisite patches above.
	default_src_prepare
}

src_compile() {
	# Options passed to all emake() calls below.
	declare -ga AGS_EMAKE
	AGS_EMAKE=(
		--directory=Engine
		LIBDIR="${EPREFIX}/usr/$(get_libdir)"
		PREFIX="${ED}/usr"
		USE_TREMOR=$(usex tremor 1 0)
	)

	emake "${AGS_EMAKE[@]}" || die '"emake" failed.'
}

src_install() {
	emake "${AGS_EMAKE[@]}" install || die '"emake" failed.'

	# Note that the "Documents" directory only contains tech notes internal to
	# AGS development and hence is ignored.
	dodoc Changes.txt Copyright.txt *.md

	DOC_CONTENTS="
	To run any AGS-based game, run the \"ags\" command with the directory or
	executable containing that game: e.g.,\\n'
	\\tags /path/to/game/\\n'
	\\tags /path/to/game/executable.exe'\\n
	\\n
	If a game fails to run, delete the \"acsetup.cfg\" file (if found) from the
	directory containing that game and try again."

	#FIXME: The "allegro" ebuild should probably have a "midi" USE flag to
	#enable such behavior. This is, arguably, outside the scope of AGS.
	# If enabling MIDI music, compile Eric A. Welsh's timidity GUS patches into
	# an Allegro-specific "patches.dat" file. For further gory details, see:
	#     http://alleg.sourceforge.net/digmid.html
	if use midi; then
		local SRC_PATCHES_CFG="${EROOT}/usr/share/timidity/eawpatches/default.cfg"
		einfo "Converting Eric A. Welsh's GUS patches to \"${EROOT}${AGS_PATCHES_DAT}\"..."
		dodir "${AGS_INSTALL_DIR}"
		pat2dat -o "${ED}${AGS_PATCHES_DAT}" "${SRC_PATCHES_CFG}" -8 ||
			die '"pat2dat" failed.'

		DOC_CONTENTS="\\n
		To enable MIDI music for a game, manually copy the
		\"${ROOT}${AGS_PATCHES_DAT}\" file into either:\\n
		* Your home directory.\\n
		* The directory containing that game.\\n
		* The system-wide \"${ROOT}usr/share/allegro/\" directory."
	fi

	# Install the above Gentoo-specific documentation.
	readme.gentoo_create_doc
}

pkg_postinst() {
	# Display the above Gentoo-specific documentation on the first installation
	# of this package.
	readme.gentoo_print_elog
}
