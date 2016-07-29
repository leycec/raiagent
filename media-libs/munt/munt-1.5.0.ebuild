# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI="6"

# "cmake-utils" phase functions take precedence over those defined by 
# "readme.gentoo-r1" and is thus inherited last.
inherit readme.gentoo-r1 cmake-utils

DESCRIPTION="Software synthesiser emulating pre-GM MIDI (e.g., Roland MT-32)"
HOMEPAGE="http://munt.sourceforge.net"

# Munt components are licensed under component-specific licenses, including:
#
# * The mandatory "mt23emu" shared library, licensed under both the GPL-2 and
#   LGPL-2.1.
# * The optional "mt23emu_qt" Qt4 frontend, licensed under only the GPL-3.
LICENSE="LGPL-2.1+ GPL-2+ GPL-3+"
SLOT="0"

#FIXME: Sadly, this makefile does *NOT* permit specifying which of
#"libsamplerate" or "libsoxr" are to be compiled against when both are
#concurrently installed. When this edge case occurs, it's unclear which
#of the two are currently compiled against. Ideally, this should be
#resolved by submitting an upstream GitHub pull request.

# While Qt support is technically optional, there exists no means of running the
# Munt's userspace daemon without installing a Qt4-based GUI. Hence, no "qt4"
# USE flag is accepted.
IUSE="+alsa libsamplerate +libsoxr pulseaudio smf2wav"
REQUIRED_USE="
	libsamplerate? ( !libsoxr )
	libsoxr? ( !libsamplerate )
	|| ( alsa pulseaudio )
"

RDEPEND="
	>=dev-qt/qtcore-4.6.0:4=
	>=dev-qt/qtgui-4.6.0:4=
	>=dev-qt/qtmultimedia-4.6.0:4=
	alsa? ( media-libs/alsa-lib:= )
	libsoxr? ( media-libs/soxr:= )
	libsamplerate? ( media-libs/libsamplerate:= )
	pulseaudio? ( media-sound/pulseaudio:= )
"
DEPEND="${RDEPEND}
	sys-devel/gcc[cxx]
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/munt/munt"
	KEYWORDS=""
else
	SRC_URI="mirror://sourceforge/${PN}/${PV}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

pkg_setup() {
	ewarn 'Munt 1.5.0 is over two years old. Unmasking and installing the live'
	ewarn 'version of Munt instead is highly recommended. For example:'
	ewarn '    $ sudo echo ">=media-libs/munt-1.5.0 **" >> /etc/portage/package.accept_keywords'
}

src_prepare() {
	# Modify the CMake-specific makefiles of all Munt components as follows:
	#
	# * Install documentation to a version-specific directory.
	# * Avoid installing license files.
	sed -e "s~share/doc/${PN}~share/doc/${P}~" \
		-e "s~COPYING\(.LESSER\)\?.txt ~~g" \
		-i */CMakeLists.txt || die '"sed" failed.'

	# Apply user-specific patches.
	eapply_user

	# Perform default logic.
	cmake-utils_src_prepare
}

src_configure() {
	# Configuration options to be passed to CMake.
	local mycmakeargs=(
		# Options defined by the top-level "CMakeLists.txt" makefile.
		-Dmunt_WITH_MT32EMU_QT=ON
		-Dmunt_WITH_MT32EMU_SMF2WAV=$(usex smf2wav ON OFF)

		# Options defined by the "mt32emu_qt/CMakeLists.txt" makefile.
		-Dmt32emu-qt_WITH_ALSA_MIDI_DRIVER=$(usex alsa ON OFF)
		-Dmt32emu-qt_USE_PULSEAUDIO_DYNAMIC_LOADING=$(usex pulseaudio ON OFF)
	)

	# Perform default logic.
	cmake-utils_src_configure
}

src_install() {
	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	Manually acquire either:\\n
	\\n
	* The \"CM32L_CONTROL.ROM\" and \"CM32L_PCM.ROM\" Roland CM-32L ROM files.\\n
	* The \"MT32_CONTROL.ROM\" and \"MT32_PCM.ROM\" Roland MT-32 ROM files.\\n
	\\n
	If in doubt, note that CM-32L ROM files are typically preferable to MT-32
	ROM files.\\n
	\\n
	To run Munt, run \"mt32emu-qt\" as a non-root user and select the ROM files
	installed above via the \"Options\" -> \"ROM Configuration...\" menu item.
	To stop Munt, close the running application. Munt must always be run as this
	userspace application rather than a system daemon."

	# If ALSA is enabled, append ALSA-specific instructions.
	if use alsa; then
		DOC_CONTENTS+="\\n
	\\n
	By default, Munt-based MIDI streams are exposed via ALSA port 128:0. To
	verify that Munt is running, grep the output of the following command for
	the strings \"MT-32\" or \"CM-32L\":\\n
	\\n
	\\tcat /proc/asound/seq/clients\\n
	\\n
	To enable DOSBox integration, set the following options in your local DOSBox
	configuration file (e.g., \"~/.dosbox/dosbox-SVN.conf\"):\\n
	\\n
	\\tmpu401=intelligent\\n
	\\tmidiconfig=128:0\\n
	"
	fi

	# Install this document.
	readme.gentoo_create_doc

	# Perform default logic.
	cmake-utils_src_install
}

pkg_postinst() {
	# Print the "README.gentoo" file installed above on first installation.
	readme.gentoo_print_elog
}
