# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

inherit distutils-r1

DESCRIPTION="Tox plugin using Python 3 venvs for Python 3 test environments"
HOMEPAGE="
	https://pypi.org/project/tox-venv
	https://github.com/tox-dev/tox-venv"

LICENSE="BSD"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
"
DEPEND="${PYTHON_DEPS}
	>=dev-python/tox-3.8.1[${PYTHON_USEDEP}]
"
RDEPEND="${PYTHON_DEPS}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/tox-dev/tox-venv.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
