# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Add functionality missing from the python libclang bindings"
HOMEPAGE="https://pypi.org/project/cymbal"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
SLOT="0"

DEPEND="dev-python/clang-python[${PYTHON_USEDEP}]"
RDEPEND="${DEPEND}"

distutils_enable_tests setup.py
