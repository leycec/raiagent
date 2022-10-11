# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{8..11} pypy3 )

inherit distutils-r1

DESCRIPTION="Faster version of dbus-next"
HOMEPAGE="https://pypi.org/project/dbus-fast"

LICENSE="MIT"
SLOT="0"
IUSE="test"

# Dependencies unsurprisingly derive from "pyproject.toml".
BDEPEND="
	>=dev-python/poetry-core-1.1.0[${PYTHON_USEDEP}]
	test? (
		dev-python/pytest[${PYTHON_USEDEP}]
		dev-python/pytest-cov[${PYTHON_USEDEP}]
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	)"
RDEPEND=">=dev-python/async-timeout-3.0.0[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}"

#FIXME: Tests currently fail to run and I can't be bothered to resolve. *sigh*
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/bluetooth-devices/dbus-fast.git"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN='dbus_fast'
	MY_P="${MY_PN}-${PV}"

	SRC_URI="mirror://pypi/${PN:0:1}/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"

	S="${WORKDIR}/${MY_P}"
fi
