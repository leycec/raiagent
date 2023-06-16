# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1

DESCRIPTION="Unbearably fast O(1) runtime type checking in pure Python"
HOMEPAGE="
	https://beartype.readthedocs.io
	https://pypi.org/project/beartype
	https://github.com/beartype/beartype
"

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
BDEPEND="
	test? (
		dev-python/mypy[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pandera[${PYTHON_USEDEP}]
		dev-python/pyright[${PYTHON_USEDEP}]
		>=dev-python/typing-extensions-3.10.0.0[${PYTHON_USEDEP}]
	)
"
RDEPEND="
	python_targets_python3_8? (
		>=dev-python/typing-extensions-3.10.0.0[${PYTHON_USEDEP}]
	)
"
DEPEND="${RDEPEND}"

#FIXME: Portage currently complains that:
#    doc/src/conf.py not found, distutils_enable_sphinx call wrong
#But "doc/src/conf.py" *DOES* exist. Let's just quietly sweep this under the
#mouldy carpet for now. </sigh>
# distutils_enable_sphinx doc/src \
#     dev-python/pydata-sphinx-theme dev-python/sphinx-autoapi

distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# fragile performance test
	beartype_test/a00_unit/a90_decor/test_decorwrapper.py::test_wrapper_fail_obj_large
)

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/beartype/beartype.git"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
else
	inherit pypi

	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi
