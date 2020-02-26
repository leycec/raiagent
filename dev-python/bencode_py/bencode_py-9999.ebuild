# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} pypy3 )

inherit distutils-r1

DESCRIPTION="Simple bencode parser"
HOMEPAGE="
	https://pypi.org/project/bencode.py
	https://github.com/fuzeman/bencode.py"

LICENSE="BOSL-1.1"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	>=dev-python/pbr-1.9.0[${PYTHON_USEDEP}]
	>=dev-python/setuptools-17.1.0[${PYTHON_USEDEP}]
"
DEPEND="${PYTHON_DEPS}"
RDEPEND="${PYTHON_DEPS}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/fuzeman/bencode.py.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN="bencode.py"
	MY_P="${MY_PN}-${PV}"

	SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"

	S="${WORKDIR}/${MY_P}"
fi
