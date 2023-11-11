# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1

DESCRIPTION="Type hints for Numpy and Pandas"
HOMEPAGE="
	https://pypi.org/project/nptyping
	https://github.com/ramonhagenaars/nptyping
"

LICENSE="MIT"
SLOT="0"

# Dependencies derive from the non-standard "dependencies/requirements.txt"
RDEPEND=">=dev-python/numpy-1.20.0[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}"

# This package is currently unmaintained and thus *NOT* worth testing, frankly.
RESTRICT="test"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/ramonhagenaars/nptyping.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	inherit pypi

	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi
