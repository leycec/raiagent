# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

#FIXME: Add support for unit tests in the "tests" subdirectory.

PYTHON_COMPAT=( python{2_7,3_3,3_4} pypy{,3} )
PYTHON_REQ_USE=tk

inherit distutils-r1

MY_PN='PyMsgBox'
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Cross-platform, pure-Python, JavaScript-like message boxes"
HOMEPAGE="https://pypi.python.org/pypi/PyMsgBox"
SRC_URI="mirror://pypi/P/${MY_PN}/${MY_P}.zip"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"
