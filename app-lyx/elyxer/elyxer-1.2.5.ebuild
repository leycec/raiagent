# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

PYTHON_COMPAT=( python2_{6,7} pypy )

# While eLyXer does bundle both an ad-hoc Python installer ("install.py") and
# ad-hoc Bourne shell installer ("make"), neither are suitable for running with
# Portage. Both behave dubiously, providing no command-line options for changing
# install paths or otherwise configuring installation behavior. The former does
# little except install "elyxer.py" to a hard-coded path; the latter appears to
# be intended for internal use, dynamically synthesizing "elyxer.py" and "docs/"
# from "src/".
#
# eLyXer also bundles numerous distutils-based "setup.py" scripts for installing
# eLyXer as a module into the current Python distribution tree. Since the
# function in "install.py" leveraging such scripts has been effectively
# disabled, we surmise such functionality to be broken.
#
# It remains unclear just why the author attempted (and failed) to reinvent the
# installer wheel. Proven methods exist, including notable Python-based build
# tools (e.g., buildit, setuptools).
#
# In the end, we elect to install eLyXer manually.
inherit python-single-r1

DESCRIPTION="LyX to HTML converter"
HOMEPAGE="http://alexfernandez.github.io/elyxer"
SRC_URI="http://alexfernandez.github.io/elyxer/dist/${P}.tar.gz"

#FIXME: Add a "css" USE flag for locally installing CSS files.
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}"

#FIXME: eLyXer provides translations in "po" installed by "install.py", which
#we should probably also install.
src_install() {
    # eLyXer bundles no sane makefiles, so this is it.
    newbin elyxer.py elyxer
    dodoc README.md
    use doc && dohtml -r docs

    # eLyXer assumes "python" to be Python 2.x. Ensure this.
    python_fix_shebang "${ED}/usr/bin/elyxer"
}
