# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

# Note that "typeguard" optionally installs a "pytest" plugin implemented as a
# setuptools-based entry point and thus requires setuptools (but probably *NOT*
# "setuptools_scm") at runtime.
DISTUTILS_USE_SETUPTOOLS=rdepend

inherit distutils-r1

DESCRIPTION="Unbearably fast O(1) runtime type checking in pure Python"
HOMEPAGE="
	https://pypi.org/project/beartype
	https://github.com/beartype/beartype"

LICENSE="MIT"
SLOT="0"
IUSE=""

# This package has no dependencies other than:
# * A build-time dependency on an arbitrary version of setuptools, which the
#   "distutils-r1" eclass already implicitly guarantees.
# * A test-time dependency on "pytest", which the following function call to
#   distutils_enable_tests() guarantees. Note this function *MUST* be called
#   after defining dependencies above (if any).
distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/beartype/beartype.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
