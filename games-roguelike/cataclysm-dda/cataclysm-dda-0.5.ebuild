# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

# List "games" last, as suggested by the "Gentoo Games Ebuild HOWTO."
inherit games git-2

# Cataclysm: DDA has yet to release source tarballs. GitHub suffices, instead.
# Since TheDarklingWolf accidentally neglected to tag 0.4, we specify the
# corresponding commit instead. See:
# https://github.com/TheDarklingWolf/Cataclysm-DDA/issues/506
DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="http://www.cataclysmdda.com"
EGIT_REPO_URI="git://github.com/TheDarklingWolf/Cataclysm-DDA.git"
EGIT_COMMIT="0.5"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# Cataclysm: DDA makefiles explicitly require "g++", GCC's C++ compiler.
RDEPEND="
	sys-libs/ncurses:5=
"
DEPEND="${RDEPEND}
	sys-devel/gcc[cxx]
"

# Absolute path of the actual directory to install Cataclysm: DDA to.
CATACLYSM_HOME="${GAMES_PREFIX}/${PN}"

# Cataclysm: DDA makefiles are surprisingly Gentoo-friendly, requiring only
# light stripping of flags.
src_prepare() {
	sed -e "/OTHERS += -O3/d" -i 'Makefile'
}

# Compile a release rather than debug build.
src_compile() {
	RELEASE=1 emake
}

# Cataclysm: DDA makefiles define no "install" target. ("A pox on yer scurvy
# grave!")
src_install() {
	# The "cataclysm" executable expects to be executed from its home directory.
	# Make a wrapper script guaranteeing this.
	games_make_wrapper "${PN}" ./cataclysm "${CATACLYSM_HOME}"

	# Install Cataclysm: DDA.
	insinto "${CATACLYSM_HOME}"
	doins -r data
	exeinto "${CATACLYSM_HOME}"
	doexe cataclysm

	# Force game-specific user and group permissions.
	prepgamesdirs

	# Since playing Cataclysm: DDA requires write access to its home directory,
	# forcefully grant such access to users in group "games". This is (clearly)
	# non-ideal, but there's not much we can do about that... at the moment.
	fperms -R g+w "${CATACLYSM_HOME}"
}

# Upgrading Cataclysm: DDA in place invites issues the user should be warned of.
pkg_postinst() {
	local cataclysm_save_dir="${CATACLYSM_HOME}/save"

	# If upgrading an installation containing a save directory, warn the user
	# that this is likely to disrupt startup with fatal errors.
	if [[ -n "${REPLACING_VERSIONS}" && -d "${cataclysm_save_dir}" ]]; then
		elog "Consider moving the Cataclysm: DDA save directory \"${cataclysm_save_dir}\""
		elog "to a new location to avoid fatal startup errors resembling:"
		elog "    terminate called after throwing an instance of 'std::out_of_range'"
		elog "      what():  basic_string::substr"
	fi
}
