# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=standalone
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1 pypi


DESCRIPTION="A clean book theme for scientific documentation with Sphinx"
HOMEPAGE="
	https://sphinx-book-theme.readthedocs.io
	https://pypi.org/project/sphinx-book-theme
	https://github.com/executablebooks/sphinx-book-theme
"
SRC_URI="
	https://github.com/executablebooks/sphinx-book-theme/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
	$(pypi_wheel_url)
"

LICENSE="BSD-with-disclosure"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

#FIXME: Enable support for calling both distutils_enable_pytest() and
#distutils_enable_sphinx() here as time permits, which it never will.
#Outstanding issues with attempting either include:
#* distutils_enable_pytest() require a number of mandatory dependencies, some of
#  which Gentoo currently fails to package.
#* distutils_enable_sphinx() violates network sandboxing in this case *AND*
#  requires an ungodly number of mandatory dependencies, many of which Gentoo
#  currently fails to package.
#
#Unsurprisingly, we lack the will to power any of this into existence. *sigh*
RESTRICT="test"

# This theme currently requires Sphinx < 7.0.0. See also this open issue:
#     https://github.com/executablebooks/sphinx-book-theme/issues/742
RDEPEND="
	>=dev-python/pydata-sphinx-theme-0.13.3[${PYTHON_USEDEP}]
	>=dev-python/sphinx-4.0.0[${PYTHON_USEDEP}]
	!>=dev-python/sphinx-7.0.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

python_compile() {
	distutils_wheel_install "${BUILD_DIR}/install" \
		"${DISTDIR}/$(pypi_wheel_name)"
}
