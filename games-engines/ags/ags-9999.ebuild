# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

#FIXME: Donate the entirety of this package to "gamerlay", which maintains a
#competing (albeit significantly out-of-date) package of the same name. As we
#lack the time and interest to actively maintain this package, donating it to
#"gamerlay" will at least ensure its continued longevity.

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

RDEPEND="
	media-libs/allegro:0
	media-libs/freetype:2
	>=media-libs/aldumb-0.9.3
	>=media-libs/dumb-0.9.3
	>=media-libs/libogg-1.3.0
	>=media-libs/libtheora-1.1.1
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
	MY_PN="${PN}_linux"
	MY_PV="v.${PV}"
	MY_P="${MY_PN}_${MY_PV}"

	SRC_URI="https://github.com/adventuregamestudio/ags/releases/download/${MY_PV}/${MY_P}.tar.xz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

# MIDI-specific installation paths.
AGS_INSTALL_DIR="usr/share/${PN}"
AGS_PATCHES_DAT="${AGS_INSTALL_DIR}/patches.dat"

src_prepare() {
	# Strip hard-coded ${CFLAGS}.
	sed -i -e "s~-O2 -g -fsigned-char~~" Engine/Makefile-defs.linux ||
		die '"sed" failed.'

	# Apply user-specific patches *AFTER* applying requisite patches above.
	default_src_prepare
}

src_compile() {
	emake --directory=Engine \
		PREFIX="${D}/usr" \
		USE_TREMOR=$(usex tremor 1 0) || die '"emake" failed.'
}

src_install() {
	emake --directory=Engine PREFIX="${D}/usr" install || die '"emake" failed.'

	# Note that the "Documents" directory only contains tech notes internal to
	# AGS development and hence is ignored.
	dodoc Changes.txt Copyright.txt *.md

	#FIXME: The "allegro" ebuild should probably have a "midi" USE flag to
	#enable such behavior. This is, arguably, outside the scope of AGS.
	# If enabling MIDI music, compile Eric A. Welsh's timidity GUS patches into
	# an Allegro-specific "patches.dat" file. For further gory details, see:
	#     http://alleg.sourceforge.net/digmid.html
	if use midi; then
		local src_patches_cfg="${ROOT}usr/share/timidity/eawpatches/default.cfg"
		einfo "Converting Eric A. Welsh's GUS patches to \"${ROOT}${AGS_PATCHES_DAT}\"..."
		dodir "/${AGS_INSTALL_DIR}"
		pat2dat -o "${D}${AGS_PATCHES_DAT}" "${src_patches_cfg}" -8 ||
			die '"pat2dat" failed.'
	fi

	DOC_CONTENTS="
	To run any AGS-based game, run the \"ags\" command with the directory or
	executable containing that game: e.g.,\\n'
	\\tags /path/to/game/\\n'
	\\tags /path/to/game/executable.exe'\\n
	\\n
	If a game fails to run, delete the \"acsetup.cfg\" file (if found) from the
	directory containing that game and try again."

	if use midi; then
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
