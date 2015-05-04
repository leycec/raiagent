# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

PYTHON_COMPAT=( python{2_7,3_3,3_4} pypy{,3} )

inherit distutils-r1

# While Voluptuous provides a PyPi page as well, their Github page is
# unsurprisingly superior.
DESCRIPTION="Python data validation library"
HOMEPAGE="https://github.com/alecthomas/voluptuous"
SRC_URI="${HOMEPAGE}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	test? ( dev-python/nose[${PYTHON_USEDEP}] )
"

python_test() {
	nosetests || die "Unit tests fail under ${EPYTHON}."
}
