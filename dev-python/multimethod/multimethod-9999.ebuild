# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} pypy3 )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Multiple argument dispatching in Python"
HOMEPAGE="
	https://coady.github.io/multimethod
	https://pypi.org/project/multimethod
	https://github.com/coady/multimethod
"

LICENSE="Apache-2.0"
SLOT="0"

BDEPEND=">=dev-python/setuptools-61.0.0[${PYTHON_USEDEP}]"

#FIXME: Package tarballs fail to ship tests, despite having previously done so.
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/coady/multimethod.git"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi
