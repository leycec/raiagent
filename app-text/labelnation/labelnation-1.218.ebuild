# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash scrictness.
set -e

# While the installed "labelnation" script requires only Python 2.x, the
# installed "csv_to_ln" script requires at least Python 2.3. Since python-r1
# fails when passed less than "python2_5", don't.
PYTHON_COMPAT=( python2_{5,6,7} )

inherit python-single-r1

DESCRIPTION="Command-line label-printing program"
HOMEPAGE="http://www.red-bean.com/labelnation"
SRC_URI="${HOMEPAGE}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}"

src_install() {
	# "labelnation" bundles no makefiles, so this is it.
	dobin csv_to_ln labelnation
	dodoc README
	docinto examples
	dodoc examples/*

	# "labelnation" assumes "python" to be Python 2.x. Correct this.
	python_fix_shebang "${ED}/usr/bin/labelnation"
}
