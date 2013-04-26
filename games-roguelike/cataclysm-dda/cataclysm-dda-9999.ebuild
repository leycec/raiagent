# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

# List "games" last, as suggested by the "Gentoo Games Ebuild HOWTO."
#inherit eutils multilib games
inherit games git-2

# Cataclysm: DDA has yet to release source tarballs. GitHub suffices, instead.
DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="http://www.cataclysmdda.com"
EGIT_REPO_URI="git://github.com/TheDarklingWolf/Cataclysm-DDA.git"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	sys-libs/ncurses:5=
"

# Cataclysm: DDA makefiles explicitly require "g++", GCC's C++ compiler.
DEPEND="${RDEPEND}
	sys-devel/gcc[cxx]
"

#S="${WORKDIR}/${MY_P}"

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
	# Directory to install Cataclysm: DDA to.
	local cataclysm_home="${GAMES_PREFIX}/${PN}"

	# The "cataclysm" executable expects to be executed from its home directory.
	# Make a wrapper script guaranteeing this.
	games_make_wrapper "${PN}" ./cataclysm "${cataclysm_home}"

	# Install Cataclysm: DDA.
	insinto "${cataclysm_home}"
	doins -r data
	exeinto "${cataclysm_home}"
	doexe cataclysm

	# Force game-specific user and group permissions.
	prepgamesdirs
}
