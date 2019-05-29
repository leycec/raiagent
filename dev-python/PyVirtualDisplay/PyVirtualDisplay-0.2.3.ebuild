# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

#FIXME: Add support for a new "screenshot" USE flag requiring the
#"dev-python/pyscreenshot" package, which will need to be created. Since that
#package only appears to depend upon "pillow" and "EasyProcess", packaging that
#package should prove trivial... in theory.

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit distutils-r1

DESCRIPTION="Python wrapper for Xvfb, Xephyr and Xvnc"
HOMEPAGE="
	https://pypi.org/project/PyVirtualDisplay
	https://github.com/ponty/PyVirtualDisplay
"

LICENSE="BSD-2"
SLOT="0"
IUSE="xauth xephyr xvfb xvnc"
REQUIRED_USE="|| ( xephyr xvfb xvnc ) ${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	dev-python/EasyProcess[${PYTHON_USEDEP}]
	xauth?  ( x11-apps/xauth )
	xephyr? ( x11-base/xorg-server[xephyr] )
	xvfb?   ( x11-base/xorg-server[xvfb] )
	xvnc?   ( net-misc/tigervnc[server] )
"
DEPEND="${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/ponty/PyVirtualDisplay"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_install_all() {
	distutils-r1_python_install_all

	dodoc README.rst docs/*.rst
}
