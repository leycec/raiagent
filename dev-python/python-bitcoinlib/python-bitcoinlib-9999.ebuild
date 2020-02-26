# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Note that the name of this package is intentionally *NOT* "bitcoinlib", an
# unrelated project with its own unique PyPI package.

PYTHON_COMPAT=( python3_{6,7,8} pypy3 )

inherit distutils-r1

DESCRIPTION="Easy interface to the Bitcoin data structures and protocol"
HOMEPAGE="
	https://pypi.org/project/python-bitcoinlib
	https://github.com/petertodd/python-bitcoinlib"

LICENSE="LGPL-3+"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${PYTHON_DEPS}
	dev-libs/openssl
"
DEPEND="${RDEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/petertodd/python-bitcoinlib.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_install_all() {
	dodoc *.md
	[[ -d examples ]] && dodoc -r examples

	distutils-r1_python_install_all
}
