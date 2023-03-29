# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} pypy3 )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION=""
HOMEPAGE="
	https://pandera.readthedocs.io
	https://pypi.org/project/pandera
	https://github.com/unionai-oss/pandera
"

LICENSE="MIT"
SLOT="0"

# Dependencies derive from "setup.py", surprisingly. "pyproject.toml" is empty.
RDEPEND="
	dev-python/multimethod[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.19.0[${PYTHON_USEDEP}]
	>=dev-python/packaging-20.0[${PYTHON_USEDEP}]
	>=dev-python/pandas-1.2.0[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
	>=dev-python/typing-inspect-0.6.0[${PYTHON_USEDEP}]
	dev-python/wrapt[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

#FIXME: Package tarballs fail to ship tests, sadly. *sigh*
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/unionai-oss/pandera.git"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

python_prepare_all() {
	# Prevent "setup.py" from installing its license file to "/usr/LICENSE.txt".
	# Doing so is awful, as reported by this Gentoo-specific error:
	#     * QA Notice: The ebuild is installing to one or more unexpected paths:
	#     *
	#     *   /usr/LICENSE.txt
	#     *
	#     * Please fix the ebuild to use correct FHS/Gentoo policy paths.
	sed -i -e '/data_files=/d' setup.py || die

	distutils-r1_python_prepare_all
}
