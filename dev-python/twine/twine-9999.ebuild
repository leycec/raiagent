# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6} )

inherit distutils-r1

DESCRIPTION="Collection of utilities for interacting with PyPI"
HOMEPAGE="
https://pypi.python.org/pypi/twine
https://github.com/pypa/twine
"

#FIXME: Add a new "doc" USE flag supporting documentation generation.
LICENSE="Apache-2.0"
SLOT="0"
IUSE="blake2 keyring test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

COMMON_DEPEND="${PYTHON_DEPS}
	>=dev-python/pkginfo-1.0[${PYTHON_USEDEP}]
	!~dev-python/requests-2.15
	!~dev-python/requests-2.16
	>=dev-python/requests-2.5.0[${PYTHON_USEDEP}]
	>=dev-python/requests-toolbelt-0.8.0[${PYTHON_USEDEP}]
	>=dev-python/setuptools-0.7.0[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.14[${PYTHON_USEDEP}]
"
DEPEND="${COMMON_DEPEND}
	test? (
		dev-python/pytest[${PYTHON_USEDEP}]
		dev-python/pretend[${PYTHON_USEDEP}]
	)
"

#FIXME: When installing under Python >= 3.6, "pyblake2" comes bundled with the
#stdlib and hence need *NOT* be installed as an external package here.
RDEPEND="${COMMON_DEPEND}
	blake2? ( dev-python/pyblake2[${PYTHON_USEDEP}] )
	keyring? ( dev-python/keyring[${PYTHON_USEDEP}] )
"

DOCS=( AUTHORS README.rst docs/. )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/pypa/twine"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx tests || die "Tests fail under ${EPYTHON}."
}
