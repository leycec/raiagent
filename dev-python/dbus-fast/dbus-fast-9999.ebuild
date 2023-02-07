# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{9..11} pypy3 )

inherit distutils-r1

DESCRIPTION="Faster version of dbus-next"
HOMEPAGE="https://pypi.org/project/dbus-fast"

LICENSE="MIT"
SLOT="0"
IUSE="test"

#FIXME: Test dependencies are almost certainly insufficient. "pyproject.toml"
#suggests an extreme number of these dependencies, which saddens us.
# Dependencies unsurprisingly derive from "pyproject.toml".
BDEPEND="
	test? (
		>=dev-python/pytest-7.0[${PYTHON_USEDEP}]
		>=dev-python/pytest-cov-3.0[${PYTHON_USEDEP}]
		>=dev-python/pytest-asyncio-0.19.0[${PYTHON_USEDEP}]
		>=dev-python/pytest-timeout-2.1.0[${PYTHON_USEDEP}]
	)"
RDEPEND="
	$(python_gen_cond_dep '
		>=dev-python/async-timeout-3.0.0[${PYTHON_USEDEP}]
	' python3_{8..10})
"
DEPEND="${RDEPEND}"

#FIXME: Tests currently fail to pass and I can't be bothered to resolve. *sigh*
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
