# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} pypy3 )
PYTHON_REQ_USE=tk

inherit distutils-r1

MY_PN='PyMsgBox'
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Cross-platform, pure-Python, JavaScript-like message boxes"
HOMEPAGE="https://github.com/asweigart/pymsgbox"
SRC_URI="mirror://pypi/P/${MY_PN}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S="${WORKDIR}/${MY_P}"
