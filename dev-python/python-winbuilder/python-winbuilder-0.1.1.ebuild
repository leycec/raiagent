# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

PYTHON_COMPAT=( python{2_7,3_3,3_4} pypy{,3} )

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
