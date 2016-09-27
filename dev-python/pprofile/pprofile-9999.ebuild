# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

PYTHON_COMPAT=( python{2_7,3_4,3_5} pypy{,3} )

inherit distutils-r1

DESCRIPTION="Line-granularity thread-aware pure-Python profiler"
HOMEPAGE="https://github.com/vpelletier/pprofile"

LICENSE="GPL-2+"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"
RDEPEND="${PYTHON_DEPS}"

DOCS=( "README.rst" )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="${HOMEPAGE}"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/p/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
