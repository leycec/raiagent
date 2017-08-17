# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

# Note that Python 3.3 is explicitly unsupported.
PYTHON_COMPAT=( python2_7 python3_{4,5,6} pypy{,3} )

inherit distutils-r1

DESCRIPTION="Python YAML schema validator"
HOMEPAGE="https://github.com/23andMe/Yamale"

LICENSE="MIT"
SLOT="0"
IUSE="ruamel test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

COMMON_DEPEND="${PYTHON_DEPS}
	dev-python/pyyaml[${PYTHON_USEDEP}]
"
RDEPEND="${COMMON_DEPEND}
	ruamel? ( >=dev-python/ruamel-yaml-0.15.0[${PYTHON_USEDEP}] )
"
DEPEND="${COMMON_DEPEND}
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/23andMe/Yamale"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/y/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx ${PN} || die "Tests fail under ${EPYTHON}."
}
