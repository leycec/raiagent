# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..9} )

inherit distutils-r1

DESCRIPTION="Python wrapper for Intel Math Kernel Library (MKL) matrix multiplication"
HOMEPAGE="https://pypi.org/project/sparse-dot-mkl"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
SLOT="0"

DEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
	sci-libs/mkl
"
RDEPEND="${DEPEND}"

DOCS=( demo.ipynb )

distutils_enable_tests pytest
