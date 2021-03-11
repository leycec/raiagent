# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

# This package optionally installs a "pytest" plugin implemented as a
# setuptools-based entry point and thus requires setuptools (but presumably
# *NOT* "setuptools_scm") at runtime.
DISTUTILS_USE_SETUPTOOLS=rdepend

inherit distutils-r1

DESCRIPTION="Python library providing run-time type checking for functions"
HOMEPAGE="
	https://pypi.org/project/typeguard
	https://github.com/agronholm/typeguard"

LICENSE="MIT"
SLOT="0"
IUSE=""

# This package requires setuptools >= 40.0.4, which the "distutils-r1"
# eclass implicitly guarantees and is thus omitted here.
BDEPEND=">=dev-python/setuptools_scm-2.0.0[${PYTHON_USEDEP}]"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/agronholm/typeguard.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
