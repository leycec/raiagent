# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )

# HoloViews imports from "distutils" at runtime.
DISTUTILS_USE_SETUPTOOLS=rdepend

inherit distutils-r1

DESCRIPTION="Make data analysis and visualization seamless and simple"
HOMEPAGE="
	https://holoviews.org
	https://pypi.org/project/holoviews
	https://github.com/holoviz/holoviews"

LICENSE="BSD"
SLOT="0"
IUSE=""

BDEPEND=">=dev-python/setuptools-30.3.0[${PYTHON_USEDEP}]"
DEPEND="
	>=dev-python/param-1.9.3[${PYTHON_USEDEP}]
	>=dev-python/pyct-0.4.4[${PYTHON_USEDEP}]
"
RDEPEND="
	dev-python/colorcet[${PYTHON_USEDEP}]
	dev-python/pandas[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/panel-0.8.0[${PYTHON_USEDEP}]
	>=dev-python/pyviz_comms-0.7.4[${PYTHON_USEDEP}]
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/holoviz/holoviews.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi
