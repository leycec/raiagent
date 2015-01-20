# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash scrictness.
set -e

EGIT_REPO_URI="git://github.com/Grognak/Grognaks-Mod-Manager.git"

# GMM requires "Python 2.6 or higher. With 3.x, there may be bugs."
PYTHON_COMPAT=( python2_7 )

# GMM requires Python Tk support.
PYTHON_REQ_USE="tk"

# While GMM has released official versions, such releases are only downloadable
# from Mediafire. Technically, we could get such releases via the "plowshares"
# utility. Sadly, Gentoo has yet to provide a "plowshares" eclass. For now,
# directly accessing the GitHub repository will have to suffice.
inherit python-single-r1 games git-2

DESCRIPTION="Grognak's Mod Manager, a \"Faster than Light\" (FTL) mod manager"
HOMEPAGE="http://www.ftlgame.com/forum/viewtopic.php?p=9994"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}"

# Directory storing user-editable state (e.g., backups, mods).
GMM_STATE_DIR="${GAMES_STATEDIR}/${PN}"

# Annoyingly, the pkg_setup() provided by eclass "games" overwrites that
# provided by eclass "python-single-r1". Define pkg_setup() to call both.
pkg_setup() {
	python-single-r1_pkg_setup
	games_pkg_setup
}

src_prepare() {
	# Patch the GMM executable to store state to the above directory.
	sed -ie 's~\(\s*dir_self = \).*~\1"'"${GMM_STATE_DIR}"'"~' main.py
}

src_install() {
	# GMM bundles no makefiles, so this is it.
	dodoc\
		README.md\
		"readme for unixlike.txt"\
		readme_changelog.txt\
		readme_modders.txt

	# Install the GMM codebase.
	local gmm_home="${GAMES_PREFIX}/${PN}"
	insinto "${gmm_home}"
	doins -r lib

	# Install the GMM executable.
	exeinto "${gmm_home}"
	doexe main.py

	# Force the GMM executable to run under Python 2.x.
	python_fix_shebang "${D}/${gmm_home}/main.py"

	# Since "games_make_wrapper" fails to produce a working wrapper, do so
	# manually.
	cat <<EOF > gmm_wrapper
#!/bin/sh
cd "${gmm_home}"
./main.py
EOF
	newgamesbin gmm_wrapper grognaks_mod_manager

	# Install GMM state directories and files.
	insinto "${GMM_STATE_DIR}"
	doins -r backup mods modman.ini

	# Force game-specific user and group permissions. Since GMM requires write
	# access to its state paths and eclass "game" provides no such access,
	# ensure this ourselves.
	prepgamesdirs
	fperms -R g+w "${GMM_STATE_DIR}"
}

pkg_postinst() {
	elog "Copy FTL mods to the user-editable state directory for Grognak's Mod Manager,"
	elog "\"${GMM_STATE_DIR}/mods\"."
}
