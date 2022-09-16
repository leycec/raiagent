# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} pypy3 )

inherit distutils-r1

DESCRIPTION="Kivy-friendly tool for packaging Python to mobile and desktop"
HOMEPAGE="https://buildozer.readthedocs.io"

LICENSE="MIT"
SLOT="0"
IUSE="android ios"

# Dependencies derive from "setup.py", as expected.
DEPEND="
	dev-python/pexpect[${PYTHON_USEDEP}]
	dev-python/sh[${PYTHON_USEDEP}]
	dev-python/virtualenv[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}
	android? ( dev-python/python-for-android[${PYTHON_USEDEP}] )
"

#FIXME: Add this line to "RDEPEND" above *AFTER* we actually create that ebuild.
	# ios? ( dev-python/kivy-ios[${PYTHON_USEDEP}] )

#FIXME: Upstream fails to bundle the "tests/" directory with source tarballs.
# distutils_enable_tests pytest
distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/kivy/buildozer.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi
