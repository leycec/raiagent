# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

inherit games

# Unreal World uses oddball version specifiers.
MY_PN="urw"
MY_PNV="${MY_PN}-${PV}"

# Unreal World is free shareware as of v3.16. Thanks, Sami and Erkka!
DESCRIPTION="Fantasy roguelike set in the far north during the late Iron-Age"
HOMEPAGE="http://www.unrealworld.fi"
SRC_URI_DIRNAME="${HOMEPAGE}/dl/linux/deb-ubuntu/10.04/"
S_PREFIX="${MY_PNV}-"
S_SUFFIX="-linux-gnu"

# Note the duplication of such basenames (sans filetype) below.
SRC_URI="
	amd64? ( ${SRC_URI_DIRNAME}${S_PREFIX}x86_64${S_SUFFIX}.tar.gz )
	x86?   ( ${SRC_URI_DIRNAME}${S_PREFIX}i486${S_SUFFIX}.tar.gz )
"

LICENSE="unreal-world"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# Unreal World's installation documentation (both offline and online) is scant
# at best. Runtime dependencies must be dynamically inspected by running in the
# same directory to which Unreal World is installed:
#
#     readelf -d urw
#
# Additional notes:
#
# * Libraries "libstdc++" and "libgcc_s" are provided by dependency
#   "sys-devel/gcc[cxx]".
# * Libraries "libc", "libdl", "libpthread", and "libm" are provided by
#   dependency "virtual/libc".
RDEPEND="
	media-libs/libsdl:0=
	media-libs/sdl-image:0=[jpeg,png]
	media-libs/sdl-mixer:0=[vorbis,wav]
	sys-devel/gcc[cxx]
"

# Unreal World is closed source and hence has no build-time dependencies.
DEPEND=""

pkg_setup() {
	# The source directory depends on the current architecture.
	if use amd64
	then S="${WORKDIR}/${S_PREFIX}x86_64${S_SUFFIX}"
	else S="${WORKDIR}/${S_PREFIX}i486${S_SUFFIX}"
	fi
}

# Naturally, Unreal World requires heavy-handed manual installation.
src_install() {
	# Directory to install ToME4 to.
	local URW_HOME="${GAMES_PREFIX}/${PN}"

	# Documentation to be installed.
	local -a URW_DOC_BASENAMES; URW_DOC_BASENAMES=(
		OLDNEWS.TXT URW.DOC news.txt )

	# Remove SDL-specific documentation, as Gentoo already supplies such
	# documentation if requested on SDL installation.
	rm README-SDL.txt

	# Install such documentation, then remove such documentation from the source
	# directory to prevent its installation below.
	dodoc "${URW_DOC_BASENAMES[@]}"
	rm    "${URW_DOC_BASENAMES[@]}"

	# Install the Unreal World executable, then remove such executable as above.
	exeinto "${URW_HOME}"
	doexe urw
	rm    urw

	# Install all Unreal World data files and directories *AFTER* removing all
	# installed files and directories above.
	insinto "${URW_HOME}"
	doins -r *

	# The "cataclysm" executable expects to be executed from its home directory.
	# Make a wrapper script guaranteeing this.
	games_make_wrapper "${PN}" ./urw "${URW_HOME}"

	# Force game-specific user and group permissions.
	prepgamesdirs

	# Since Unreal World requires write access to its home directory,
	# forcefully grant such access to users in group "games". This is (clearly)
	# non-ideal, but there's not much we can do about that... at the moment.
	fperms g+w "${URW_HOME}"
}
