# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{9..11} )

inherit distutils-r1

DESCRIPTION="Build and share machine learning and data science web apps"
HOMEPAGE="https://streamlit.io"

LICENSE="Apache-2.0"
SLOT="0"

# Dependencies derive from "lib/setup.py" with the caveat that mandatory runtime
# dependencies are the union of these two lists defined in that file:
# * "INSTALL_REQUIRES".
# * "SNOWPARK_CONDA_EXCLUDED_DEPENDENCIES". (Don't ask. Just don't.)
#
# Note that:
# * Streamlit tarballs currently contain *NO* documentation or tests. /shrug/
# * Streamlit itself is housed under the "lib/" subdirectory of the official
#   Streamlit GitHub repository at:
#       https://github.com/streamlit/streamlit/tree/develop/lib
RDEPEND="
	dev-python/GitPython[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/python-dateutil[${PYTHON_USEDEP}]
	dev-python/semver[${PYTHON_USEDEP}]
	dev-python/toml[${PYTHON_USEDEP}]
	dev-python/watchdog[${PYTHON_USEDEP}]
	>=dev-python/altair-3.2.0[${PYTHON_USEDEP}]
	>=dev-python/blinker-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/cachetools-4.0[${PYTHON_USEDEP}]
	>=dev-python/click-7.0[${PYTHON_USEDEP}]
	>=dev-python/importlib_metadata-1.4[${PYTHON_USEDEP}]
	>=dev-python/packaging-14.1[${PYTHON_USEDEP}]
	>=dev-python/pandas-0.21.0[${PYTHON_USEDEP}]
	>=dev-python/pillow-6.2.0[${PYTHON_USEDEP}]
	>=dev-python/pydeck-0.1.0[${PYTHON_USEDEP}]
	>=dev-python/protobuf-python-3.12[${PYTHON_USEDEP}]
	>=dev-python/pyarrow-4.0[${PYTHON_USEDEP}]
	>=dev-python/pympler-0.9[${PYTHON_USEDEP}]
	>=dev-python/requests-2.4[${PYTHON_USEDEP}]
	>=dev-python/rich-10.11.0[${PYTHON_USEDEP}]
	>=dev-python/tornado-5.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-3.10.0.0[${PYTHON_USEDEP}]
	>=dev-python/tzlocal-1.1[${PYTHON_USEDEP}]
	>=dev-python/validators-0.2[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

#FIXME: Enable pytest-based testing after Streamlit tarballs begin bundling
#tests. Since the Streamlit GitHub repository currently contains tests, it's
#likely their tarballs will begin bundling tests... at some point.
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/streamlit/streamlit.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

python_prepare_all() {
	# Prevent "setup.py" from installing Windows-specific executables.
	sed -i -e '/streamlit\.cmd/d' setup.py || die

	distutils-r1_python_prepare_all
}
