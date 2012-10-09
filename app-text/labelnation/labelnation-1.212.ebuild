# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=4

# Enforce Bash scrictness.
set -e

# While the installed "labelnation" script requires only Python 2.x, the
# installed "csv_to_ln" script requires at least Python 2.3. Since
# "python.eclass" fails with error for less than Python 2.5, use that instead.
PYTHON_DEPEND="2:2.5"

# "labelnation" installs only Python 2.x-specific stand-alone scripts.
SUPPORT_PYTHON_ABIS=
RESTRICT_PYTHON_ABIS="3.*"

inherit python

DESCRIPTION="Command-line label-printing program"
HOMEPAGE="http://www.red-bean.com/labelnation"
SRC_URI="${HOMEPAGE}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

#DEPEND=""
#RDEPEND="${DEPEND}"

src_prepare() {
	# "labelnation" assumes "python" to be Python 2.x.
	python_convert_shebangs 2 csv_to_ln labelnation
}

src_install() {
	# "labelnation" bundles no makefiles, so this is it.
	dobin csv_to_ln labelnation
	dodoc README
	docinto examples
	dodoc examples/*
}
