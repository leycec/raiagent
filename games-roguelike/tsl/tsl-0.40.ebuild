# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=4

# Enforce Bash strictness.
set -e

inherit games

DESCRIPTION="The Slimy Lichmummy, an adventure game similar in style to the classic Rogue"
HOMEPAGE="http://www.happyponyland.net/roguelike.php"
SRC_URI="http://www.happyponyland.net/files/${P}.tar.gz"

LICENSE="tsl"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="allegro ncurses"
REQUIRED_USE="|| ( allegro ncurses )"

RDEPEND="
	virtual/libc
	allegro? ( media-libs/allegro )
	ncurses? ( sys-libs/ncurses )
"

# TSL leverages shell scripts explicitly calling "gcc". We are most displeased.
DEPEND="${RDEPEND}
	sys-devel/gcc
"

src_prepare() {
	# Inject user $CFLAGS into the TSL shell scripts.
	sed -e 's~^\(gcc.*\)\\$~\1 '"${CFLAGS}"' \\~' -i *.sh
}

# Technically, we should be running "nbuild.php" to rebuild TSL shell scripts on
# a per-system basis. But that requires adding a build-time PHP dependency,
# which smacks of overkill. For now, just run the bundled shell scripts.
src_compile() {
	# If the current requests requests both graphical and console builds, rename
	# the executable output by the latter but not former. The former retains the
	# default executable filename, as expected.
	if use allegro && use ncurses; then
		einfo 'Compiling console interface...'
		./build_console.sh
		mv tsl tsl_console
		einfo 'Compiling graphical interface...'
		./build_gui.sh
	# Otherwise, accept the default executable of "tsl".
	elif use allegro; then
		einfo 'Compiling graphical interface...'
		./build_gui.sh
	else # use ncurses
		einfo 'Compiling console interface...'
		./build_console.sh
	fi
}

src_install() {
	# The console build is entirely self-contained in the compiled executable.
	# Install such executable directly, if compiled.
	if use ncurses; then
		if use allegro
		then dogamesbin tsl_console
		else dogamesbin tsl
		fi
	fi

	# The graphical build requires assets external to the compiled executable.
	# Install such files in a dedicated directory, if compiled.
	if use allegro; then
		# Install graphical assets.
		local tsl_home="${GAMES_PREFIX}/${PN}"
		insinto "${tsl_home}"
		doins *.{png,tga}

		# Install the graphical executable, which expects to be executed from
		# within such directory.
		exeinto "${tsl_home}"
		doexe tsl

		# Since "games_make_wrapper" fails to produce a working wrapper, do so
		# manually.
		cat <<EOF > tsl_wrapper
#!/bin/sh
cd "${tsl_home}"
./tsl
EOF
		newgamesbin tsl_wrapper tsl
	fi

	# Install documentation and configuration examples.
	dodoc CHANGES.TXT README.TXT
	docinto examples
	dodoc tsl_conf_*

	# Force game-specific user and group permissions.
	prepgamesdirs
}
