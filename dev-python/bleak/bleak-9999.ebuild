# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="Bluetooth Low Energy platform Agnostic Klient (BLEAK) for Python"
HOMEPAGE="https://bleak.readthedocs.io"

LICENSE="MIT"
SLOT="0"

BDEPEND="test? ( dev-python/pytest-asyncio[${PYTHON_USEDEP}] )"
RDEPEND="dev-python/dbus_next[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/hbldh/bleak.git"
	EGIT_BRANCH="develop"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
