# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#FIXME: VGMPlay 0.40.9 (i.e., the most recent stable release of VGMPlay) no
#longer compiles under modern compilers. Thankfully, the live version of VGMPlay
#still compiles. See also this open issue:
#    https://github.com/vgmrips/vgmplay/issues/95
#FIXME: VGMPlay has been obsoleted by "vgmplay-libvgm", a modular rewrite of
#VGMPlay by the same author... in theory, anyway. In practice, VGMPlay has
#recently begun to receive git commits while "vgmplay-libvgm" has gone moribund.
#In short, we have *NO* idea there the state of VGMPlay is. See also:
#    https://github.com/vgmrips/vgmplay
#    https://github.com/ValleyBell/vgmplay-libvgm

EAPI="8"

inherit readme.gentoo-r1 xdg

DESCRIPTION="Video game music (VGM) file command-line player"
HOMEPAGE="http://vgmrips.net/forum/viewtopic.php?t=112"

# VGMPlay licensing can only be referred to as "extreme." Frankly, the authors
# themselves do not appear to particularly care about licensing or even know
# which licenses apply and when to VGMPlay. The "VGMPlay/licenses/List.txt" file
# purports to be the canonical list of all licenses associated with third-party
# VGMPlay components but nonetheless lists three components for which the
# license is literally unknown:
#
#     Ootake - ?
#     MEKA - ?
#     in_wsr - ?
#
# VGMPlay itself appears to remain unlicensed.
#
# I've never encountered a licensing scenario this painfully disfunctional. If
# even the principal developers of VGMPlay cannot be bothered to either license
# their software *OR* attribute third-party software embedded in their software,
# we certainly cannot be expected to do so. We instead note that, since numerous
# VGMPlay components are GPL 2-licensed, the infectious virality of the GPL
# requires extending that license to VGMPlay itself. Ergo, GPL 2.
#
# See also the following outstanding VGMPlay issue:
#     https://github.com/vgmrips/vgmplay/issues/47
LICENSE="GPL-2"
SLOT="0"

IUSE="alsa ao debug opl pulseaudio"
REQUIRED_USE=""

DEPEND="
	sys-libs/zlib
	virtual/libc
	ao? ( media-libs/libao )
"

# VGMPlay indirectly supports ALSA and PulseAudio via OSS runtime emulation in
# the high-level "vgm-player" script. Something is better than nothing.
#
# Note that, although the "pulseaudio' package provides an "oss" USE flag, this
# flag has been deprecated; since this package now unconditionally installs
# "padsp", the PulseAudio OSS wrapper, merely installing "pulseaudio" suffices.
RDEPEND="${DEPEND}
	alsa? ( media-libs/alsa-oss )
	pulseaudio? ( media-sound/pulseaudio )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/vgmrips/vgmplay"
	KEYWORDS=""
else
	SRC_URI="https://github.com/vgmrips/vgmplay/archive/${PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Prevent the "readme.gentoo-r1" eclass from autoformatting documentation via
# the external "fmt" and "echo -e" commands for readability.
DISABLE_AUTOFORMATTING=1

#FIXME: Uncomment this line to test "readme.gentoo-r1" documentation.
#FORCE_PRINT_ELOG=1

src_prepare() {
	default
	xdg_environment_reset

	# Remove the bundled "zlib" directory.
	rm -r VGMPlay/zlib || die

	# Munge the makefile as follows:
	# * Strip hardcoded ${CFLAGS}.
	# * Strip execution of "xdg-"-prefixed installation commands (e.g.,
	#   "xdg-icon-resource") in favour of "xdg" eclass utilities.
	sed -e '/CFLAGS := -O3/s~ -O3~~' \
		-e '/\(xdg-desktop-menu\|xdg-icon-resource\|xdg-mime\)/d' \
		-i VGMPlay/Makefile || die
}

src_compile() {
	# List of all options to be passed to VGMPlay's makefile, globalized to
	# allow reuse in the src_install() phase.
	declare -ga VGMPLAY_MAKE_OPTIONS
	VGMPLAY_MAKE_OPTIONS=(
		PREFIX="${EROOT}/"usr
		DESTDIR="${D}"
		USE_LIBAO=$(usex ao 1 0)
		DEBUG=$(usex debug 1 0)
		DISABLE_HWOPL_SUPPORT=$(usex opl 0 1)
	)

	# VGMPlay only provides a GNU "Makefile"; notably, no autotools-based
	# "configure" script is provided.
	emake --directory=VGMPlay "${VGMPLAY_MAKE_OPTIONS[@]}"
}

src_install() {
	# Absolute path of the system-wide VGMPlay directory.
	VGMPLAY_DIR="${EPREFIX}/usr/share/${PN}"

	# Absolute path of the system-wide VGMPlay configuration file.
	VGMPLAY_CFG_FILE="${EPREFIX}/etc/vgmplay.ini"

	# Create all directories assumed to exist by this makefile.
	exeinto usr/bin

	# Install all VGMPlay commands (e.g., "vgm-player") and manpages.
	emake --directory=VGMPlay play_install "${VGMPLAY_MAKE_OPTIONS[@]}"

	# Link this configuration file from its default non-standard path into a
	# more standard directory.
	dosym "${VGMPLAY_DIR}/vgmplay.ini" "${VGMPLAY_CFG_FILE}"

	# Install all remaining documentation.
	dodoc VGMPlay/VGMPlay*.txt

	# Install all XDG-managed files to standard system directories. Note that
	# the xdg_pkg_preinst() function subsequently inspects these directories for
	# these files.
	insinto usr/share/applications
	doins VGMPlay/xdg/vgmplay.desktop
	insinto usr/share/icons
	doins VGMPlay/xdg/icons/*.png
	insinto usr/share/mime
	doins VGMPlay/xdg/vgmplay-mime.xml

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="VGMPlay supports audio files of filetype \"vgm\" and \"vgz\"
(gzip-compressed \"vgm\") and \"m3u\" playlists of these files, available for
effectively all sequenced video game music from the online archive at:

	http://vgmrips.net

To enable support for files ripped from devices containing OPL4 sound chips
(e.g., MSX), manually download and copy the \"yrw801.rom\" file into the
system-wide \"${VGMPLAY_DIR}\" directory:

	sudo mv yrw801.rom ${VGMPLAY_DIR}/

To play supported files, run the \"vgm-player\" wrapper:

    # See the \"vgmplay\" manpage for key bindings.
    vgm-player bubbleman.vgz

To convert supported files to another format, pipe the \"vgm2pcm\" command into
a suitable audio encoder:

    # Convert VGZ to MP3 via \"lame\".
    vgm2pcm bubbleman.vgz - | lame -r - -

VGMPlay is configurable via the system-wide \"${VGMPLAY_CFG_FILE}\" file."

	# Install this document.
	readme.gentoo_create_doc
}

pkg_postinst() {
	xdg_pkg_postinst

	# Print the "README.gentoo" file installed above on first installation.
	readme.gentoo_print_elog
}
