# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7,8} )

inherit distutils-r1

DESCRIPTION="pytest plugin for PyQt4 or PyQt5 applications"
HOMEPAGE="
	https://pypi.org/project/pytest-qt https://github.com/pytest-dev/pytest-qt"

LICENSE="MIT"
SLOT="0"
IUSE="doc"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${PYTHON_DEPS}
	>=dev-python/pytest-2.7.0[${PYTHON_USEDEP}]
	|| (
		dev-python/PyQt5[gui,testlib,${PYTHON_USEDEP}]
		dev-python/pyside:2[gui,testlib,${PYTHON_USEDEP}]
	)
	doc? (
		dev-python/sphinx[${PYTHON_USEDEP}]
		dev-python/sphinx-py3doc-enhanced-theme[${PYTHON_USEDEP}]
	)
"
DEPEND="${PYTHON_DEPS}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/pytest-dev/pytest-qt"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Test make assumptions about Qt environment
RESTRICT="test"

python_compile_all() {
	use doc && sphinx-build -b html docs _build/html
}

python_install_all() {
	use doc && HTML_DOCS=( _build/html/. )
	dodoc *.rst
	distutils-r1_python_install_all
}
