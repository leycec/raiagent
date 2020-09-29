# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

inherit distutils-r1

DESCRIPTION="Python SDK for Dropbox API v2"
HOMEPAGE="
	https://pypi.org/project/dropbox
	https://github.com/dropbox/dropbox-sdk-python"

#FIXME: Add support for the "doc" USE flag (e.g., by running "make html" from
#the "docs" subdirectory).

# While "dropbox-sdk" does offer tests, they require a user-specific OAuth2
# authentication token and hence cannot be automated here.
LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/pytest-runner[${PYTHON_USEDEP}]
"
RDEPEND="${PYTHON_DEPS}
	dev-python/urllib3[${PYTHON_USEDEP}]
	>=dev-python/six-1.3.0[${PYTHON_USEDEP}]
	>=dev-python/requests-2.16.2[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/dropbox/dropbox-sdk-python"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN='dropbox'
	MY_P="${MY_PN}-${PV}"

	SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

DOCS=( README.rst )
