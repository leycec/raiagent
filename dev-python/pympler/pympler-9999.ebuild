# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1

DESCRIPTION="Measure, monitor and analyze the memory behavior of Python objects"
HOMEPAGE="https://pympler.readthedocs.io"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="charts"

#FIXME: File an upstream issue. Or... not. Upstream is basically dead, which is
#why pympler is probably in this mess to begin with. *sigh*
#FIXME: Unbundle Bottle, a micro web framework that Pympler absolutely should
#*NOT* be bundling. What a potential security disaster! See prior comment.

# Dependencies derive from external sources, due to being erroneously omitted
# from both "pyproject.toml" and "setup.py". See also the Fedora spec at:
#     https://src.fedoraproject.org/rpms/python-Pympler/blob/rawhide/f/python-Pympler.spec
RDEPEND="
	charts? (
		dev-python/matplotlib[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
	)
"
DEPEND="${RDEPEND}"

#FIXME: Enable Sphinx-based documentation generation.
# distutils_enable_sphinx doc dev-python/sphinx_rtd_theme

#FIXME: Uncomment after upstream resolves failing tests, including:
#* "test_repr_function", failing on at least Python 3.8.
#* "test_otracker_diff", which appears to infinitely busy-wait.
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/pympler/pympler.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN=Pympler
	MY_P="${MY_PN}-${PV}"

	SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"

	S="${WORKDIR}/${MY_P}"
fi
