# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

PYTHON_COMPAT=( python2_{6,7} pypy )

# Felipe's official repository is incompatible with Mercurial >= 3.2. Since 
# fingolfin's unofficial fork fixes both this and other pressing issues, we
# currently prefer the latter. This is subject to change, of course.
EGIT_REPO_URI="https://github.com/fingolfin/git-remote-hg.git"
EGIT_BRANCH="master"

inherit python-single-r1 git-2

DESCRIPTION="Official Mercurial bridge from the Git project"
HOMEPAGE="https://github.com/felipec/git-remote-hg"

#FIXME: Add support for unit tests in the top-level "test" directory.
LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	>=dev-vcs/mercurial-3.2.3
"
DEPEND="${RDEPEND}"

# Despite being Python-based, git-remote-hg leverages autotools. Go figure.
src_install() {
	emake prefix="${D}/usr" install install-doc || die 'Installation failed.'
	dodoc README.asciidoc doc/SubmittingPatches
}
