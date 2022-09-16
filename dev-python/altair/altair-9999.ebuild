# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1

DESCRIPTION="Declarative statistical visualization library"
HOMEPAGE="https://altair-viz.github.io"

LICENSE="BSD"
SLOT="0"

# Dependencies derive from "requirements.txt", which "setup.py" reads.
RDEPEND="
	dev-python/entrypoints[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/toolz[${PYTHON_USEDEP}]
	>=dev-python/jinja-2.0.0[${PYTHON_USEDEP}]
	>=dev-python/jsonschema-3.0[${PYTHON_USEDEP}]
	>=dev-python/pandas-0.18[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

#FIXME: Enable Sphinx-based documentation generation. Doing so will prove
#non-trivial, as Altair's documentation configuration (i.e., "doc/conf.py")
#requires non-standard Altair-specific Sphinx extensions. *sigh*
# distutils_enable_sphinx doc dev-python/sphinx_rtd_theme

#FIXME: Enable pytest-based testing. Unlike Sphinx, doing so will prove trivial,
#as Altair's test suite only requires a single Python package not currently
#packaged elsewhere: the Altair-specific "vega_datasets" package, which itself
#only requires Pandas. \o/
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/altair-viz/altair.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi
