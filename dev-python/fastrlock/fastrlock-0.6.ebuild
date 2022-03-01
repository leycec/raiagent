# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Fast RLock implementation for CPython"
HOMEPAGE="https://pypi.org/project/fastrlock/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
SLOT="0"

# Technically, "fastrlock" only optionally requires Cython. Pragmatically, an
# uncythonized "fastrlock" is slower than "threading.RLock" and thus pointless.
BEPEND="dev-python/cython[${PYTHON_USEDEP}]"

# TODO: Tests currently fail due to Cython build path issues:
#    E   ImportError: cannot import name 'rlock' from 'fastrlock'
# distutils_enable_tests pytest

python_configure_all() {
	mydistutilsargs=( --with-cython )
}
