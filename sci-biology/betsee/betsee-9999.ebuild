# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{4,5,6} )

inherit distutils-r1

DESCRIPTION="Bioelectric Tissue Simulation Engine Environment (BETSEE)"
HOMEPAGE="https://gitlab.com/betse/betsee"

LICENSE="BSD-2"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#FIXME: Constrain the following "pyside:2" and "pyside-tools:2" dependencies to
#minimum required versions *AFTER* a stable version of PySide2 is released.

# This list of mandatory dependencies derives directly from the
# "betsee.metadata.DEPENDENCIES_RUNTIME_MANDATORY" list, which is enforced at
# BETSEE runtime and hence guaranteed to be authorative.
#
# Note that the PySide2 "svg" USE flag implies the "widget" USE flag implies the
# "gui" USE flag, which thus need not be explicitly listed.
DEPEND="${PYTHON_DEPS}
	dev-python/pyside:2[${PYTHON_USEDEP},svg]
	dev-python/pyside-tools:2[${PYTHON_USEDEP}]
	>=sci-biology/betse-${PV}[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://gitlab.com/betse/betsee.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_install_all() {
	distutils-r1_python_install_all

	# Recursively install all available documentation.
	dodoc -r README.rst doc/*
}
