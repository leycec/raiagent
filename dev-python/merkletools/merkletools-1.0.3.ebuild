# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} pypy3 )

inherit distutils-r1

DESCRIPTION="Merkle Tools"
HOMEPAGE="
	https://pypi.org/project/merkletools
	https://github.com/Tierion/pymerkletools"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
DEPEND="${PYTHON_DEPS}
	>=dev-python/pysha3-1.0.0
"
RDEPEND="${DEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/Tierion/pymerkletools.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_prepare_all() {
	# Prevent "setup.py" from installing the ambiguously named "tests" package,
	# preventing Portage from failing with the following fatal error:
	#     * Package installs 'tests' package which is forbidden and likely a bug in the build system.
	# See also this open issue:
	#     https://github.com/Tierion/pymerkletools/issues/19
	sed -i -e \
		's~\bfind_packages()~find_packages(exclude=["tests"])~' setup.py || die

	distutils-r1_python_prepare_all
}
