# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=5

# Note that Python 3.3 is explicitly unsupported.
PYTHON_COMPAT=( python{2_7,3_4,3_5} pypy{,3} )

inherit distutils-r1 git-r3

DESCRIPTION="Python SDK for the Dropbox API"
HOMEPAGE="https://github.com/dropbox/dropbox-sdk-python"
SRC_URI=""
EGIT_REPO_URI="${HOMEPAGE}"

#FIXME: Add support for the "doc" USE flag (e.g., by running "make html" from
#the "docs" subdirectory).

# While "dropbox-sdk" does offer tests, running such tests requires a user-
# specific OAuth2 authentication token and hence cannot be automated here.
LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/urllib3[${PYTHON_USEDEP}]
	>=dev-python/six-1.3.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
