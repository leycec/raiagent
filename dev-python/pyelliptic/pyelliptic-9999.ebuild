# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 python3_{5,6,7} pypy{,3} )

inherit distutils-r1

DESCRIPTION="Deprecated Python OpenSSL wrapper"
HOMEPAGE="
	https://pypi.org/project/pyelliptic
	https://github.com/yann2192/pyelliptic"

LICENSE="BSD-2"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/yann2192/pyelliptic.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
