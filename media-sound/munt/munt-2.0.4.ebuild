# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
EAPI="6"

# "cmake-utils" phase functions take precedence over those defined by all other
# eclasses and are thus inherited last.
inherit readme.gentoo-r1 multilib cmake-utils

DESCRIPTION="Software synthesiser emulating pre-GM MIDI (e.g., Roland MT-32)"
HOMEPAGE="https://github.com/munt/munt"

# Munt components are licensed under component-specific licenses, including:
#
# * The mandatory "mt23emu" shared library, licensed under both the GPL-2 and
#   LGPL-2.1.
# * The optional "mt23emu_qt" Qt4 frontend, licensed under only the GPL-3.
LICENSE="LGPL-2.1+ GPL-2+ GPL-3+"
SLOT="0"

#FIXME: Add support for a new "clang" USE flag. Currently, Munt appears to
#default to GCC and only fallback to clang in the absence of GCC.

IUSE="alsa c cpp libsamplerate libsoxr portaudio pulseaudio qt4 +qt5 smf2wav static"
REQUIRED_USE="
	|| ( alsa portaudio pulseaudio )
	?? ( libsamplerate libsoxr )
	?? ( qt4 qt5 )
"

RDEPEND="
	alsa? ( media-libs/alsa-lib )
	libsoxr? ( media-libs/soxr )
	libsamplerate? ( media-libs/libsamplerate )
	portaudio? ( media-libs/portaudio )
	pulseaudio? ( media-sound/pulseaudio )
	qt4? (
		>=dev-qt/qtcore-4.6.0:4
		>=dev-qt/qtgui-4.6.0:4
		>=dev-qt/qtmultimedia-4.6.0:4
	)
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtmultimedia:5
	)
	smf2wav? ( dev-libs/glib:2 )
"
DEPEND="${RDEPEND}
	|| ( sys-devel/clang sys-devel/gcc[cxx] )
"

# DOCS=(
# 	README.txt
# 	mt32emu{_qt,}/{AUTHORS,NEWS,README,TODO}.txt
# 	mt32emu_smf2wav/{AUTHORS,README}.txt
# )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="${HOMEPAGE}"
	KEYWORDS=""
else
	MY_PV="${PV//./_}"
	MY_P="libmt32emu_${MY_PV}"

	SRC_URI="https://github.com/${PN}/${PN}/archive/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"

	# Craziest top-level tarball directory evar.
	S="${WORKDIR}/${PN}-${MY_P}"
fi

src_prepare() {
	# Modify the CMake makefiles of all Munt components as follows:
	#
	# * Install documentation to a version-specific directory.
	# * Avoid installing license files.
	sed -e 's~share/doc/'${PN}'~share/doc/'${P}'~' \
		-e 's~COPYING\(.LESSER\)\?.txt ~~g' \
		-i */CMakeLists.txt || die '"sed" failed.'

	# Apply user-specific patches.
	eapply_user

	# Perform default logic.
	cmake-utils_src_prepare
}

src_configure() {
	# Value of the ${PROJECT_NAME} variable expanded by the
	# "mt32emu/CMakeLists.txt" makefile and required below.
	if [[ ${PV} == 9999 ]]
	then MY_PROJECT_NAME=libmt32emu
	else MY_PROJECT_NAME=mt32emu-qt
	fi

	# Configuration options to be passed to CMake.
	local mycmakeargs=(
		# Options defined by the top-level "CMakeLists.txt" makefile.
		-Dmunt_WITH_MT32EMU_QT=ON
		-Dmunt_WITH_MT32EMU_SMF2WAV=$(usex smf2wav)

		# Options defined by the "mt32emu/CMakeLists.txt" makefile.
		-Dlibmt32emu_SHARED=$(usex static OFF ON)
		-Dlibmt32emu_C_INTERFACE=$(usex c)
		-Dlibmt32emu_CPP_INTERFACE=$(usex cpp)

		# This makefile expects a non-standard option for specifying the desired
		# library basename rather than the standard "CMAKE_INSTALL_LIBDIR" option.
		-DLIB_INSTALL_DIR="${EPREFIX}/usr/$(get_libdir)"

		# If an external audio resampling library is enabled, disable Munt's
		# internal audio resampling library; else, enable this library.
		# Unfortunately, the name of this option conditionally depends on
		# whether this is a stable or live build.
		-D${MY_PROJECT_NAME}_WITH_INTERNAL_RESAMPLER=$(
			(use libsamplerate || use libsoxr) && echo 'off' || echo 'on')

		# Options defined by the "mt32emu_qt/CMakeLists.txt" makefile.
		-Dmt32emu-qt_WITH_ALSA_MIDI_SEQUENCER=$(usex alsa)
		-Dmt32emu-qt_USE_PULSEAUDIO_DYNAMIC_LOADING=$(usex pulseaudio)
		-Dmt32emu-qt_WITH_QT5=$(usex qt5)

		# Options implicitly defined by the "mt32emu_qt/CMakeLists.txt" makefile
		# for use in conditionally disabling find_package() calls.
		-DCMAKE_DISABLE_FIND_PACKAGE_ALSA=$(usex !alsa)
		-DCMAKE_DISABLE_FIND_PACKAGE_PORTAUDIO=$(usex !portaudio)
		-DCMAKE_DISABLE_FIND_PACKAGE_PulseAudio=$(usex !pulseaudio)
		-DCMAKE_DISABLE_FIND_PACKAGE_LibSoxr=$(usex !libsoxr)
		-DCMAKE_DISABLE_FIND_PACKAGE_LibSamplerate=$(usex !libsamplerate)
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
