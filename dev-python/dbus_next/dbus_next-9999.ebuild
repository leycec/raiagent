# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="The next great DBus library for Python with asyncio support"
HOMEPAGE="https://python-dbus-next.readthedocs.io"

LICENSE="MIT"
SLOT="0"

BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/pytest-timeout[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/sphinxcontrib-asyncio \
	dev-python/sphinxcontrib-fulltoc

#FIXME: Uncomment after upstream resolves this open issue by bundling requisite
#test files with release tarballs:
#    https://github.com/altdesktop/python-dbus-next/issues/94
RESTRICT="test"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/altdesktop/python-dbus-next.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
