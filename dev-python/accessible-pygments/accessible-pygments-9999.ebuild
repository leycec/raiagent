# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} pypy3 )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Accessible pygments themes"
HOMEPAGE="
	https://github.com/Quansight-Labs/accessible-pygments
	https://pypi.org/project/accessible-pygments
"

LICENSE="BSD"
SLOT="0"

RDEPEND=">=dev-python/pygments-1.5[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/Quansight-Labs/accessible-pygments"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~ia64 ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
fi

python_prepare_all() {
	# Prevent this package from erroneously installing the test-specific "test/"
	# directory as another package.
	sed -i -e 's~\bfind_packages()~find_packages(exclude=("test",))~' \
		setup.py || die '"sed" failed.'

	distutils-r1_python_prepare_all
}
