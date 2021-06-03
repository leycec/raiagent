# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..9} )

inherit distutils-r1

DESCRIPTION="Easier Pythonic interface to VTK"
HOMEPAGE="https://docs.pyvista.org"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
SLOT="0"

RDEPEND="
	dev-python/appdirs[${PYTHON_USEDEP}]
	dev-python/imageio[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	sci-libs/vtk[python]
	!>=dev-python/meshio-5.0.0[${PYTHON_USEDEP}]
	>=dev-python/meshio-4.0.3[${PYTHON_USEDEP}]
	>=dev-python/scooby-0.5.1[${PYTHON_USEDEP}]
	>=dev-python/transforms3d-0.3.1[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
