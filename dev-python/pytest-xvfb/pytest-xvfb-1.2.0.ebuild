# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#FIXME: Officially, "pytest-xvfb" only supports Python <= 3.5. Pragmatically,
#"pytest-xvfb" appears to behave as expected on Python > 3.5 as well. See also:
#    https://github.com/The-Compiler/pytest-xvfb/issues/20
PYTHON_COMPAT=( python2_7 python3_{4,5,6,7,8} )

inherit distutils-r1

DESCRIPTION="pytest plugin to run Xvfb for tests"
HOMEPAGE="
	https://pypi.org/project/pytest-xvfb
	https://github.com/The-Compiler/pytest-xvfb
"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${PYTHON_DEPS}
	>=dev-python/PyVirtualDisplay-0.2.1[xvfb,${PYTHON_USEDEP}]
	>=dev-python/pytest-2.8.1[${PYTHON_USEDEP}]
"
DEPEND="${PYTHON_DEPS}"

DOCS=( CHANGELOG.rst README.rst )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/The-Compiler/pytest-xvfb"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
