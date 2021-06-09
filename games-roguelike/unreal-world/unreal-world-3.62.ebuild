# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit readme.gentoo-r1

DESCRIPTION="Fantasy roguelike set in the far north during the late Iron-Age"
HOMEPAGE="http://www.unrealworld.fi"

# UnReal World uses oddball version specifiers, just because.
MY_PN="urw"
MY_P="${MY_PN}-${PV}"
SRC_URI_PREFIX="http://www.unrealworld.fi/dl/${PV}/linux/deb-ubuntu/${MY_P}"
SRC_URI="
	amd64? ( ${SRC_URI_PREFIX}-x86_64-linux-gnu.tar.gz )
	x86?   ( ${SRC_URI_PREFIX}-i686-linux-gnu.tar.gz )
"

LICENSE="UNREAL-WORLD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# UnReal World is free shareware as of v3.16, but remains closed-source and
# thus has *NO* build-time dependencies.
#
# Installation documentation (both offline and online) remains scant. Runtime
# dependencies must be dynamically inspected by running in the same directory
# to which UnReal World is installed:
#     readelf -d urw
# Additional notes:
# * "libstdc++" and "libgcc_s" are provided by "sys-devel/gcc[cxx]".
# * "libc", "libdl", "libpthread", and "libm" are provided by "virtual/libc".
BDEPEND=""
DEPEND=""
RDEPEND="
	acct-group/gamestat
	media-libs/libsdl2
	media-libs/sdl2-image[jpeg,png]
	media-libs/sdl2-mixer[vorbis,wav]
	media-libs/sdl2-net
	sys-devel/gcc[cxx]
"

# Prevent the "readme.gentoo-r1" eclass from autoformatting documentation via
# the external "fmt" and "echo -e" commands for readability.
DISABLE_AUTOFORMATTING=1

#FIXME: Uncomment this line to test "readme.gentoo-r1" documentation.
#FORCE_PRINT_ELOG=1

# Absolute dirname of the system directory to install UnReal World to.
URW_DIRNAME="/usr/share/${PN}"

# Basename of the UnReal World executable.
URW_BIN_BASENAME=urw3-bin

# Array of the basenames of all documentation to be installed.
URW_DOC_BASENAMES=( OLDNEWS.TXT news.txt )

# Set the source directory depending on the current architecture.
pkg_setup() {
	if use amd64
	then S="${WORKDIR}/${MY_P}-x86_64-linux-gnu"
	else S="${WORKDIR}/${MY_P}-i686-linux-gnu"
	fi
}

src_install() {
	# Install (and then remove) this documentation.
	dodoc "${URW_DOC_BASENAMES[@]}"
	rm    "${URW_DOC_BASENAMES[@]}" || die

	# Install (and then remove) this executable into URW's system directory.
	exeinto "${URW_DIRNAME}"
	doexe "${URW_BIN_BASENAME}"
	rm    "${URW_BIN_BASENAME}" || die

	# Remove SDL-specific documentation, which Gentoo already supplies.
	# rm README-SDL.txt || die

	# Remove Ubuntu-specific directories.
	rm -rf ubuntu || die

	# Install all remaining paths into URW's system directory.
	insinto "${URW_DIRNAME}"
	doins -r *

	# Create a wrapper script running URW from its system directory.
	cat <<EOF > "${T}"/${PN}
#!/usr/bin/env sh
pushd "${EPREFIX}/${URW_DIRNAME}" >/dev/null
./${URW_BIN_BASENAME}
exit_code=$?
popd >/dev/null
exit ${exit_code}
EOF
	dobin "${T}"/${PN}

	# URW expects to have write access to its system directory. To do so, run
	# URW under the "gamestate" group and grant that group access.
	fowners root:gamestat "${URW_DIRNAME}" /usr/bin/${PN} || die
	fperms g+w "${URW_DIRNAME}" || die
	fperms g+s /usr/bin/${PN} || die

	# Generate Gentoo-specific documentation.
	DOC_CONTENTS="Add each user running UnReal World to the \"gamestat\" group: e.g.,
	$ usermod -a -G gamestat username"
	readme.gentoo_create_doc
}

# Print the "README.gentoo" file installed above on first installation.
pkg_postinst() {
	readme.gentoo_print_elog
}
