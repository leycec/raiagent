# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="Unbearably fast O(1) runtime type checking in pure Python"
HOMEPAGE="https://pypi.org/project/beartype"

LICENSE="MIT"
SLOT="0"

# This package has no dependencies other than:
# * A build-time dependency on an arbitrary version of setuptools, which the
#   "distutils-r1" eclass already implicitly guarantees.
# * A test-time dependency on "pytest", which the following function call to
#   distutils_enable_tests() guarantees. Note this function *MUST* be called
#   after defining dependencies above (if any).
#
# Nonetheless, we depend on a reasonably recent version of "typing_extensions"
# under Python 3.8.x, as doing so provides a substantially improved experience
# when using beartype validators or NumPy type hints (i.e., "numpy.typing").
RDEPEND="
	python_targets_python3_8? (
		>=dev-python/typing-extensions-3.10.0.0[${PYTHON_USEDEP}]
	)
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

#FIXME: Enable when we actually provide meaningful Sphinx documentation. Note
#that beartype requires Sphinx >= 4.1.0, but that distutils_enable_sphinx()
#fails to support a minimum Sphinx version requirement. We'll at least need to
#specify that manually and possibly drop distutils_enable_sphinx() altogether.
# distutils_enable_sphinx doc dev-python/sphinx_rtd_theme

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
