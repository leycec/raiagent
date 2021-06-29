# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Robust and effective logging for Python 2 and 3"
HOMEPAGE="https://pypi.org/project/logzero/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
SLOT="0"

# BDEPEND="
# 	test? (
# 		dev-python/h5py[${PYTHON_USEDEP}]
# 		dev-python/netcdf4-python[${PYTHON_USEDEP}]
# 	)
# "

distutils_enable_tests pytest
