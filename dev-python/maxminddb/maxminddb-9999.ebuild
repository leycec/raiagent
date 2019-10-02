# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{5,6,7} pypy3 )

inherit distutils-r1

DESCRIPTION="Python MaxMind DB reader extension"
HOMEPAGE="
	https://pypi.org/project/maxminddb
	https://github.com/maxmind/MaxMind-DB-Reader-python"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${PYTHON_DEPS}
	dev-libs/libmaxminddb
"
DEPEND="${RDEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/maxmind/MaxMind-DB-Reader-python.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_install_all() {
	dodoc *.rst
	[[ -d examples ]] && dodoc -r examples

	distutils-r1_python_install_all
}
