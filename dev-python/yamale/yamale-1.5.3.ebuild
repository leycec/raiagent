# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=5

# Note that Python 3.3 is explicitly unsupported.
PYTHON_COMPAT=( python{2_7,3_4,3_5} pypy{,3} )

inherit distutils-r1

DESCRIPTION="Python YAML schema validator"
HOMEPAGE="https://github.com/23andMe/Yamale"
SRC_URI="mirror://pypi/y/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	dev-python/pyyaml[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )
"

S="${WORKDIR}/Yamale-${PV}"

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx ${PN} || die "Tests fail under ${EPYTHON}."
}
