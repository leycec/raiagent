# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

# Note that there intentionally exists *NO* "mpremote-9999.ebuild", as
# "mpremote" is officially embedded with the official MicroPython repository
# itself (under the "tools/mpremote" subdirectory) rather than as an
# independent repository.
DESCRIPTION="MicroPython remote control"
HOMEPAGE="https://pypi.org/project/mpremote"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# Install-time dependencies derive from "pyproject.toml".
BDEPEND="dev-python/wheel[${PYTHON_USEDEP}]"

# Runtime dependencies derive from the "[options]" section of "setup.cfg".
DEPEND=">=dev-python/pyserial-3.3[${PYTHON_USEDEP}]"
RDEPEND="${DEPEND}"
