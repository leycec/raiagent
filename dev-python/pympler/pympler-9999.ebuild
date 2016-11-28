# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

PYTHON_COMPAT=( python{2_7,3_4,3_5} )

inherit distutils-r1

DESCRIPTION="Memory profiler of Python objects in running Python applications"
HOMEPAGE="https://github.com/pympler/pympler"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="doc test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
	test? ( dev-python/bottle[${PYTHON_USEDEP}] )
"
RDEPEND="${PYTHON_DEPS}
	dev-python/bottle[${PYTHON_USEDEP}]
"

DOCS=( "README.md" )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="${HOMEPAGE}"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN="Pympler"
	MY_P="${MY_PN}-${PV}"

	SRC_URI="mirror://pypi/P/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"

	S="${WORKDIR}"/${MY_P}
fi

python_prepare_all() {
	# Remove all bundled third-party dependencies.
	rm pympler/util/bottle.py || die '"rm" failed.'

	#FIXME: Remove this conditional after the release of Pympler 0.4.5.
	# If this is an older stable version of Pympler, coerce Pympler to import
	# the system rather than bundled version of Bottle.
	if [[ ${PV} < 0.4.4 ]]; then
		sed \
			-e '/import bottle/s:^.*$:import bottle:g' \
			-i pympler/web.py || die '"sed" failed.'
	fi

	distutils-r1_python_prepare_all
}

python_test() {
	# https://github.com/pympler/pympler/issues/22
	esetup.py try
}

python_install_all() {
	use doc && local HTML_DOCS=( doc/html/. )
	distutils-r1_python_install_all
}
