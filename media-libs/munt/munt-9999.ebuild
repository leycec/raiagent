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

#FIXME: Add support for a new "clang" USE flag. Currently, Munt appears to
#default to GCC and only fallback to clang in the absence of GCC.

# While Qt support is technically optional, there exists no means of running the
# Munt's userspace daemon without installing either the Qt4- or Qt5-based GUI.
# Hence, either the "qt4" or "qt5" USE flags are requisite.
IUSE="+alsa libsamplerate +libsoxr portaudio pulseaudio qt4 +qt5 smf2wav"
REQUIRED_USE="
	|| ( alsa portaudio pulseaudio )
	|| ( libsamplerate libsoxr )
	|| ( qt4 qt5 )
"

RDEPEND="
	alsa? ( media-libs/alsa-lib:= )
	libsoxr? ( media-libs/soxr:= )
	libsamplerate? ( media-libs/libsamplerate:= )
	portaudio? ( media-libs/portaudio:= )
	pulseaudio? ( media-sound/pulseaudio:= )
	qt4? (
		>=dev-qt/qtcore-4.6.0:4=
		>=dev-qt/qtgui-4.6.0:4=
		>=dev-qt/qtmultimedia-4.6.0:4=
	)
	qt5? (
		dev-qt/qtcore:5=
		dev-qt/qtgui:5=
		dev-qt/qtmultimedia:5=
	)
"
DEPEND="${RDEPEND}
	|| ( sys-devel/clang sys-devel/gcc[cxx] )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/munt/munt"
	KEYWORDS=""
else
	SRC_URI="mirror://sourceforge/${PN}/${PV}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

src_prepare() {
	# Modify the CMake makefiles of all Munt components as follows:
	#
	# * Install documentation to a version-specific directory.
	# * Avoid installing license files.
	sed -e 's~share/doc/'${PN}'~share/doc/'${P}'~' \
		-e 's~COPYING\(.LESSER\)\?.txt ~~g' \
		-i */CMakeLists.txt || die '"sed" failed.'

	# Disable all attempts in the CMake makefile for the "mt32emu-qt" component
	# to autodetect optional dependencies by calling find_package() and
	# unconditionally enable support for those dependencies if detected. While
	# this makefile does expose options pertaining to those dependencies (e.g.,
	# "-Dmt32emu-qt_WITH_ALSA_MIDI_SEQUENCER"), these options govern only the
	# enabling and disabling of dependency-specific features rather than the
	# enabling and disabling of those dependencies.
	#
	# Note, however, that we *CANNOT* simply unconditionally disable these
	# attempts. Doing so also prevents critical variables describing these
	# dependencies (e.g., "${ALSA_LIBRARIES}") from being defined. To circumvent
	# this, these attempts are moved from their default lines into the if
	# conditionals testing the existence of these dependencies. (It works.)
	sed -e '/^\s*find_package(\(ALSA\|PORTAUDIO\|PulseAudio\|LibSoxr\|LibSamplerate\))$/d' \
		-e 's~^\(\s*if(ALSA_FOUND)\)$~\1\n  find_package(ALSA)~' \
		-e 's~^\(\s*if(PORTAUDIO_FOUND)\)$~\1\n  find_package(PORTAUDIO)~' \
		-e 's~^\(\s*if(PULSEAUDIO_FOUND)\)$~\1\n  find_package(PulseAudio)~' \
		-e 's~^\(\s*if(LIBSOXR_FOUND)\)$~\1\n    find_package(LibSoxr)~' \
		-e 's~^\(\s*if(LIBSAMPLERATE_FOUND)\)$~\1\n      find_package(LibSamplerate)~' \
		-i mt32emu_qt/CMakeLists.txt || die '"sed" failed.'

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
		-Dmt32emu-qt_WITH_ALSA_MIDI_SEQUENCER=$(usex alsa ON OFF)
		-Dmt32emu-qt_USE_PULSEAUDIO_DYNAMIC_LOADING=$(usex pulseaudio ON OFF)
		-Dmt32emu-qt_WITH_QT5=$(usex qt5 ON OFF)

		# Options internally tested by the "mt32emu_qt/CMakeLists.txt" makefile
		# to enable or disable support for optional dependencies. These options
		# are *NOT* intended to be passed externally, but no alternative exists.
		-DALSA_FOUND=$(usex alsa ON OFF)
		-DPORTAUDIO_FOUND=$(usex portaudio ON OFF)
		-DPULSEAUDIO_FOUND=$(usex pulseaudio ON OFF)
		-DLIBSOXR_FOUND=$(usex libsoxr ON OFF)
		-DLIBSAMPLERATE_FOUND=$(usex libsamplerate ON OFF)
	)

	# If an external audio resampling library is enabled, disable Munt's
	# internal audio resampling library.
	if use libsamplerate || use libsoxr; then
		mycmakeargs+=( -Dmt32emu-qt_WITH_INTERNAL_RESAMPLER=OFF )
	# Else, enable Munt's internal audio resampling library.
	else
		mycmakeargs+=( -Dmt32emu-qt_WITH_INTERNAL_RESAMPLER=ON )
	fi

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
