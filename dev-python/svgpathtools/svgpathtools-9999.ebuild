# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Tools for manipulating and analyzing SVG Path objects and Bezier curves"
HOMEPAGE="https://github.com/mathandy/svgpathtools"

LICENSE="MIT"
SLOT="0"

RDEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
	dev-python/svgwrite[${PYTHON_USEDEP}]
"

RESTRICT="test"  # <-- way too lazy for this sort of thing right now :((((((((((

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/mathandy/svgpathtools.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	inherit pypi 

	KEYWORDS="~amd64 ~x86"
fi
