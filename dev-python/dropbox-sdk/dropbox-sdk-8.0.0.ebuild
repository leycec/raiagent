# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

# Note that Python 3.3 is explicitly unsupported.
PYTHON_COMPAT=( python2_7 python3_{4,5,6} pypy{,3} )

inherit distutils-r1

DESCRIPTION="Python SDK for Dropbox API v2"
HOMEPAGE="https://github.com/dropbox/dropbox-sdk-python"

#FIXME: Add support for the "doc" USE flag (e.g., by running "make html" from
#the "docs" subdirectory).

# While "dropbox-sdk" does offer tests, they require a user-specific OAuth2
# authentication token and hence cannot be automated here.
LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	dev-python/urllib3[${PYTHON_USEDEP}]
	>=dev-python/six-1.3.0[${PYTHON_USEDEP}]
	>=dev-python/requests-2.5.1[${PYTHON_USEDEP}]
	!~dev-python/requests-2.6.1
	!~dev-python/requests-2.16.0
	!~dev-python/requests-2.16.1
"
DEPEND="${RDEPEND}
	dev-python/pytest-runner
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="${HOMEPAGE}"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN="dropbox-sdk-python"
	MY_P="${MY_PN}-${PV}"

	SRC_URI="https://github.com/dropbox/dropbox-sdk-python/archive/v${PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

python_install_all() {
	distutils-r1_python_install_all

	dodoc README.rst docs/*.rst
}
