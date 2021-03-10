# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} pypy3 )

inherit distutils-r1

DESCRIPTION="Python packaging Common Tasks"
HOMEPAGE="
	https://pypi.org/project/pyct
	https://github.com/pyviz-dev/pyct"

LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND=">=dev-python/param-1.7.0[${PYTHON_USEDEP}]"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/pyviz-dev/pyct.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
