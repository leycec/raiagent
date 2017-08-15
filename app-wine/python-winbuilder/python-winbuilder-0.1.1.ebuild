# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{3,4} pypy{,3} )

inherit distutils-r1

DESCRIPTION="MinGW-based build environment for Python projects"
HOMEPAGE="https://github.com/ogrisel/python-winbuilder"
SRC_URI="${HOMEPAGE}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND=""
DEPEND="${RDEPEND}"

python_install_all() {
	distutils-r1_python_install_all

	# Install supplementary configuration files as examples.
	docinto example
	dodoc {.,}*.yml Dockerfile
}
