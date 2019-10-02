# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{5,6,7} )

inherit distutils-r1

DESCRIPTION="Bioelectric Tissue Simulation Engine Environment (BETSEE)"
HOMEPAGE="https://gitlab.com/betse/betsee"

LICENSE="BSD-2"
SLOT="0"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#FIXME: Constrain the following "pyside2" and "pyside-tools:2" dependencies to
#minimum required versions *AFTER* a stable version of PySide2 is released.

# This list of mandatory dependencies derives directly from the
# "betsee.metadata.DEPENDENCIES_RUNTIME_MANDATORY" list, which is enforced at
# BETSEE runtime and hence guaranteed to be authorative.
#
# Note that:
#
# * The PySide2 "svg" USE flag implies the "widget" USE flag, which implies the
#   "gui" USE flag, which thus need not be explicitly listed.
# * Each version of BETSEE requires the same version of BETSE, excluding the
#   trailing patch number of this version of BETSEE (e.g., BETSEE 0.9.0.0 and
#   0.9.0.1 both require exactly BETSE 0.9.0). Since newer versions of BETSE
#   typically break backward compatibility with older versions of BETSEE, this
#   dependency does *NOT* extend to newer versions of BETSE.
COMMON_DEPEND="${PYTHON_DEPS}
	dev-python/pyside2[${PYTHON_USEDEP},svg]
	dev-python/pyside2-tools[${PYTHON_USEDEP}]
	~sci-biology/betse-${PV%.*}[${PYTHON_USEDEP}]
"
DEPEND="${COMMON_DEPEND}
	test? (
		dev-python/pytest-qt[${PYTHON_USEDEP}]
		dev-python/pytest-xvfb[${PYTHON_USEDEP}]
		>=dev-python/pytest-3.7.0[${PYTHON_USEDEP}]
	)
"
RDEPEND="${COMMON_DEPEND}"

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

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx || die "Tests fail under ${EPYTHON}."
}

python_install_all() {
	distutils-r1_python_install_all

	#FIXME: Uncomment the line containing "doc/*" *AFTER* we actually populate
	#that subdirectory with meaningful documentation.

	# Recursively install all available documentation.
	# dodoc -r README.rst doc/*
	dodoc -r README.rst
}
