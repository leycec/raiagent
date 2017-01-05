# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

PYTHON_COMPAT=( python{2_7,3_4,3_5} )

inherit distutils-r1

DESCRIPTION="Collection of utilities for interacting with PyPI"
HOMEPAGE="https://github.com/pypa/twine"

#FIXME: Add a new "doc" USE flag supporting documentation generation.
LICENSE="Apache-2.0"
SLOT="0"
IUSE="keyring test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

COMMON_DEPEND="${PYTHON_DEPS}
	dev-python/clint
	>=dev-python/pkginfo-1.0[${PYTHON_USEDEP}]
	>=dev-python/requests-2.5.0[${PYTHON_USEDEP}]
	>=dev-python/requests-toolbelt-0.5.1[${PYTHON_USEDEP}]
	>=dev-python/setuptools-0.7.0[${PYTHON_USEDEP}]
"
DEPEND="${COMMON_DEPEND}
	test? (
		dev-python/pytest[${PYTHON_USEDEP}]
		dev-python/pretend[${PYTHON_USEDEP}]
	)
"

# This package's optional BLAKE2 runtime dependency is explicitly omitted, as:
#
# * There currently exists no "dev-python/pyblake2" package.
# * Python 3.6 ships out-of-the-box support for BLAKE2, obsoleting that package.
RDEPEND="${COMMON_DEPEND}
	keyring? ( dev-python/keyring[${PYTHON_USEDEP}] )
"

DOCS=( AUTHORS README.rst )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="${HOMEPAGE}"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"

	# S="${WORKDIR}"/${MY_P}
fi

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx tests || die "Tests fail under ${EPYTHON}."
}
