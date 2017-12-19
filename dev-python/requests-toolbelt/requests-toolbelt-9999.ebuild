# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6} )

inherit distutils-r1

DESCRIPTION="Utility belt for advanced users of python-requests"
HOMEPAGE="
http://toolbelt.readthedocs.io/en/latest
https://pypi.python.org/pypi/requests-toolbelt
https://github.com/requests/toolbelt
"

#FIXME: Add a new "doc" USE flag supporting documentation generation.
LICENSE="Apache-2.0"
SLOT="0"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	<dev-python/requests-3.0.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	test? (
		dev-python/betamax[${PYTHON_USEDEP}]
		dev-python/mock[${PYTHON_USEDEP}]
		dev-python/pytest[${PYTHON_USEDEP}]
	)
"

DOCS=( AUTHORS.rst HISTORY.rst README.rst )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/requests/toolbelt"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -v || die "Tests fail under ${EPYTHON}."
}
